// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { UserFactory } from "test-utils/UserFactory.sol";

import { TallyToken } from "src/policies/TallyToken.sol";
import "src/Kernel.sol";
import "src/modules/TOKEN.sol";

contract TokenTest is Test {
    Kernel internal kernel;
    Token internal token;
    TallyToken internal tallyToken;

    address public deployer;
    address public user;
    UserFactory public userFactory;

    bytes public err;

    function setUp() public {
        userFactory = new UserFactory();
        address[] memory users = userFactory.create(3);
        deployer = users[0]; // deployer is admin/executor by default so it is the address that grants roles
        user = users[1]; // EOA to be used as control address without granted roles

        vm.startPrank(deployer);
        kernel = new Kernel();
        token = new Token(kernel);
        tallyToken = new TallyToken(kernel);

        // grant COMPTROLLER role to deployer and to kernel
        Role COMPTROLLER = token.COMPTROLLER();
        kernel.grantRole(COMPTROLLER, deployer);
        kernel.grantRole(COMPTROLLER, address(kernel));
        
        vm.stopPrank();
    }

    // test TOKEN module was installed properly
    function testInstallTokenModule() public {
        // COMPTROLLER role was already set for deployer in setUp()
        vm.prank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        
        Keycode tokenKeycode = token.KEYCODE();

        Module installedToken = kernel.getModuleForKeycode(tokenKeycode);
        assertEq(address(installedToken), address(token));
        Keycode installedKeycode = kernel.getKeycodeForModule(installedToken);
        assertEq(fromKeycode(installedKeycode), fromKeycode(tokenKeycode));
        Keycode addedKeycode = kernel.allKeycodes(0);
        assertEq(fromKeycode(addedKeycode), fromKeycode(tokenKeycode));
    }

    // test TallyToken policy is activated properly
    // properly configured permissions are required for any Policy to be deployed
    function testActivateTallyTokenPolicy() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        vm.stopPrank();

        // check Policy was set to active
        bool activeStatus = tallyToken.isActive();
        assertTrue(activeStatus);
        // check Kernel policy registry updates ran smoothly
        Policy activatedTallyToken = kernel.activePolicies(0);
        assertEq(address(activatedTallyToken), address(tallyToken));
        uint256 firstPolicy = kernel.getPolicyIndex(tallyToken);
        assertEq(firstPolicy, 0);

        // check Kernel's dependencies recordkeeping
        Keycode tokenKeycode = toKeycode("TOKEN");
        Policy newDependent = kernel.moduleDependents(tokenKeycode, 0);
        assertEq(address(newDependent), address(tallyToken));
        uint256 newDependentIndex = kernel.getDependentIndex(tokenKeycode, tallyToken);
        assertEq(newDependentIndex, 0);
    }

    // test public mint() function works properly when called
    // mint() is not a policy function as it is permissionless for anyone to call
    function testMint() public {
        // mint as deployer
        vm.prank(deployer);
        token.mint();

        // after minting to deployer, check balance of deployer and owner of tokenId 1
        uint256 deployerBalance = token.balanceOf(deployer);
        address firstOwner = token.ownerOf(1);
        assertEq(deployerBalance, 1);
        assertEq(firstOwner, deployer);

        // mint as user
        vm.prank(user);
        token.mint();

        // after minting to user, check balance of deployer and owner of tokenId 2
        uint256 userBalance = token.balanceOf(user);
        address secondOwner = token.ownerOf(2);
        assertEq(userBalance, 1);
        assertEq(secondOwner, user);
    }

    // test COMPTROLLER-restricted mintTo() function works properly
    // mintTo() is not a policy function as it is only intended for sparse and rare usage
    function testMintTo() public {
        // mintTo as deployer
        vm.prank(deployer);
        token.mintTo(user, 5);

        // after minting to user, check balance of user
        uint256 userBalance = token.balanceOf(user);
        assertEq(userBalance, 5);

        // check owner of tokenId 1-5
        for (uint256 i; i < userBalance; i++) {
            address owner = token.ownerOf(i + 1);
            assertEq(owner, user);
        }
    }

    // test TOKEN module's mintTo() can not be called by address without role COMPTROLLER
    // mintTo() is not a policy function and does not require policy activation as it is restricted to Medici team
    function testComptrollerRole() public {
        Role comptroller = token.COMPTROLLER();
        bytes memory error = abi.encodeWithSelector(Module_OnlyRole.selector, comptroller);
        vm.expectRevert(error);
        vm.prank(user);
        token.mintTo(user, 1);
    }

    // test transferFrom() cannot be called directly on module and is disabled initially at policy level
    function testTransferFromDisabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 1);
        vm.stopPrank();

        bytes memory errorPermissioned = abi.encodeWithSelector(Module_PolicyNotAuthorized.selector, address(this));
        bytes4 errorDisabled = Token_TransferDisabled.selector;
        uint256 userBalance = 1; // tokenId 1 was minted

        // ensure transferFrom() cannot be called on module contract
        vm.prank(user);
        token.approve(address(this), userBalance);
        vm.expectRevert(errorPermissioned);
        token.transferFrom(user, address(this), 1);

        // ensure transferFrom() is disabled on TallyToken policy to start
        vm.expectRevert(errorDisabled);
        tallyToken.transferFrom(user, address(this), 1);
    }

    // test safeTransferFrom() cannot be called directly on module and is disabled initially at policy level
    function testSafeTransferFromDisabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 1);
        vm.stopPrank();

        bytes memory errorPermissioned = abi.encodeWithSelector(Module_PolicyNotAuthorized.selector, address(this));
        bytes4 errorDisabled = Token_TransferDisabled.selector;
        uint256 userBalance = 1; // tokenId 1 was minted

        // ensure transferFrom() cannot be called on module contract
        vm.prank(user);
        token.approve(address(this), userBalance);
        vm.expectRevert(errorPermissioned);
        token.safeTransferFrom(user, address(this), 1);

        // ensure transferFrom() is disabled on TallyToken policy to start
        vm.expectRevert(errorDisabled);
        tallyToken.safeTransferFrom(user, address(this), 1);
    }
}