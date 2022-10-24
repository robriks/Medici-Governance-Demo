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

    // test minting through TallyToken policy
    function testMintWithDelegate() public {
        // install module and activate policy
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        vm.stopPrank();

        // mint as deployer
        vm.prank(deployer);
        tallyToken.mintWithDelegate();

        // after minting to deployer, check balance of deployer and owner of tokenId 1
        uint256 deployerBalance = token.balanceOf(deployer);
        address firstOwner = token.ownerOf(1);
        assertEq(deployerBalance, 1);
        assertEq(firstOwner, deployer);

        // mint as user
        vm.prank(user);
        tallyToken.mintWithDelegate();

        // after minting to user, check balance of deployer and owner of tokenId 2
        uint256 userBalance = token.balanceOf(user);
        address secondOwner = token.ownerOf(2);
        assertEq(userBalance, 1);
        assertEq(secondOwner, user);
    }

    // test transfer and transferFrom can be enabled only by Medici admins
    // performs a transfer
    function testToggleTransfersEnabled() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 2);
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

        address prevOwner2 = token.ownerOf(2);
        assertEq(prevOwner2, user);

        vm.prank(user);
        tallyToken.safeTransferFrom(user, deployer, 2);

        address newOwner2 = token.ownerOf(2);
        assertEq(newOwner2, deployer);
    }
    
    // test transfer edge cases when approvals are revoked or modified
    function testTransferEdgeCases() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        token.mintTo(user, 2);
        vm.stopPrank();

        // enable transfers
        vm.prank(deployer);
        tallyToken.toggleTransfersAllowed();
        assertTrue(tallyToken.transfersAllowed());

        // revoke approval and transfer with revoked approval
        vm.startPrank(user);
        token.approve(address(0), 1);
        tallyToken.transferFrom(user, address(this), 1);
        vm.stopPrank();
        
        address newOwner = token.ownerOf(1);
        assertEq(newOwner, address(this));

        // change approval and safeTransfer with altered approval
        vm.startPrank(user);
        token.approve(deployer, 2);
        tallyToken.safeTransferFrom(user, deployer, 2);
        vm.stopPrank();

        address newOwner2 = token.ownerOf(2);
        assertEq(newOwner2, deployer);
    }

    // test delegations, first with mints and then redelegations
    function testDelegations() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));

        uint256 voteWeightBefore = token.getVotes(user);
        assertEq(voteWeightBefore, 0);
        token.mintTo(user, 1);
        vm.stopPrank();

        // ensure mintTo() increments vote weight and provided delegation to 'to'
        uint256 voteWeightAfter = token.getVotes(user);
        assertEq(voteWeightAfter, 1);
        
        address to = token.delegates(user);
        assertEq(to, user);

        // ensure mint() increments vote weight and provides delegation to self
        uint256 voteWeightPre = token.getVotes(user);
        assertEq(voteWeightPre, voteWeightAfter);
        
        vm.prank(user);
        tallyToken.mintWithDelegate();
        
        uint256 voteWeightPost = token.getVotes(user);
        assertEq(voteWeightPost, voteWeightPre + 1);

        address self = token.delegates(user);
        assertEq(self, user);
    }

    // test various redelegate() scenarios to catch any edge cases
    // includes delegation with 0 balance, redelegation after mint, and redelegation after transfer
    // keep in mind that redelegations do not delete mapping entries, but rather adjust their votes via checkpoint balances using OZ Checkpoints.sol
    function testRedelegate() public {
        vm.startPrank(deployer);
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        vm.stopPrank();

        uint256 voteWeightBefore = token.getVotes(user);
        assertEq(voteWeightBefore, 0);

        // attempt delegation without token balance
        bytes memory error = abi.encodeWithSelector(Token_NotEnoughTokens.selector);
        vm.expectRevert(error);
        vm.prank(user, user);
        tallyToken.redelegate(deployer);
        
        vm.prank(user);
        tallyToken.mintWithDelegate();

        uint256 voteWeight = token.getVotes(user);
        assertEq(voteWeight, voteWeightBefore + 1);
        address self = token.delegates(user);
        assertEq(self, user);

        // redelegate after minting
        vm.prank(user, user);
        tallyToken.redelegate(deployer);

        uint256 voteWeightAfter = token.getVotes(user);
        assertEq(voteWeightAfter, 0);
        address newDelegate = token.delegates(user);
        assertEq(newDelegate, deployer);
        uint256 voteWeightDelegated = token.getVotes(deployer);
        assertEq(voteWeightDelegated, 1);

        // enable transfers then transfer after redelegating
        vm.prank(deployer);
        tallyToken.toggleTransfersAllowed();
        vm.prank(user);
        tallyToken.transferFrom(user, deployer, 1);

        // redelegate to user
        vm.prank(deployer, deployer);
        tallyToken.redelegate(user);

        uint256 voteWeightRedelegated = token.getVotes(deployer);
        assertEq(voteWeightRedelegated, 0);
        address transferDelegate = token.delegates(deployer);
        assertEq(transferDelegate, user);
        uint256 voteWeightTransfered = token.getVotes(user);
        assertEq(voteWeightTransfered, 1);
    }
}