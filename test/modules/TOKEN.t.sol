// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { UserFactory } from "test-utils/UserFactory.sol";

import { Token } from "src/modules/TOKEN.sol";
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

        // grant COMPTROLLER role to deployer(self) and to kernel
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

    // test TallyToken policy was activated properly
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

    // test TOKEN module's mintTo() can only be called by address with role COMPTROLLER
    function testComptrollerRole() public {
        Role comptroller = token.COMPTROLLER();
        bytes memory error = abi.encodeWithSelector(Module_OnlyRole.selector, comptroller);
        vm.expectRevert(error);
        vm.prank(user);
        token.mintTo(user, 1);
    }

    // test transfer() cannot be called on TOKEN module and is disabled initially on TallyToken policy
    function testTransferDisabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        vm.stopPrank();
        
        bytes memory errorPermissioned = abi.encodeWithSelector(Module_PolicyNotAuthorized.selector, deployer);
        bytes4 errorDisabled = Token_TransferDisabled.selector;
        
        // ensure tokens cannot be transferred on module contract
        vm.expectRevert(errorPermissioned);
        vm.prank(deployer);
        token.transfer(user, 1);
        
        // ensure tokens cannot be transferred on policy contract while transfers are disabled
        vm.expectRevert(errorDisabled);
        vm.prank(deployer);
        tallyToken.transfer(user, 1);
    }

    // test transferFrom() is disabled initially
    function testTransferFromDisabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 100);
        vm.stopPrank();

        bytes memory errorPermissioned = abi.encodeWithSelector(Module_PolicyNotAuthorized.selector, address(this));
        bytes4 errorDisabled = Token_TransferDisabled.selector;
        uint256 userBalance = token.balanceOf(user);

        // ensure transferFrom() cannot be called on module contract
        vm.prank(user);
        token.approve(address(this), userBalance);
        vm.expectRevert(errorPermissioned);
        token.transferFrom(user, address(this), 1);

        // ensure transferFrom() is disabled on TallyToken policy to start
        vm.expectRevert(errorDisabled);
        tallyToken.transferFrom(user, address(this), 1);
    }

    // test transfer and transferFrom can be enabled only by Medici admins
    function testToggleTransfersEnabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 100);
        vm.stopPrank();

        // ensure unauthorized users cannot flip transfersEnabled boolean
        Role comptroller = token.COMPTROLLER();
        bytes memory errorNotComptroller = abi.encodeWithSelector(Policy_OnlyRole.selector, comptroller);
        vm.expectRevert(errorNotComptroller);
        vm.prank(user);
        tallyToken.toggleTransfersAllowed();

        // ensure deployer address was properly granted COMPTROLLER role
        assertTrue(kernel.hasRole(deployer, comptroller));

        // then check deployer can enable transfers via toggleTransfersAllowed()
        vm.prank(deployer);
        tallyToken.toggleTransfersAllowed();
        assertTrue(tallyToken.transfersAllowed());
    }

    //todo test delegations function to delegates works properly

    //todo set executor to governance module
}