// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { UserFactory } from "test-utils/UserFactory.sol";

import { TallyToken } from "src/policies/TallyToken.sol";
import "src/Kernel.sol";
import "src/modules/TOKEN.sol";

contract TallyTokenTest is Test {
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

// test transfer and transferFrom can be enabled only by Medici admins
    function testToggleTransfersEnabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 1);
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

        // transfer for good measure
        address prevOwner = token.ownerOf(1);
        assertEq(prevOwner, user);
        
        vm.prank(user);
        tallyToken.transferFrom(user, address(this), 1);
        
        address newOwner = token.ownerOf(1);
        assertEq(newOwner, address(this));
    }
}