// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";
import { UserFactory } from "test-utils/UserFactory.sol";
import "openzeppelin-contracts/governance/TimelockController.sol";

import "src/Kernel.sol";
import "src/modules/GOVRN.sol";
import "src/modules/TOKEN.sol";
import "src/policies/TallyToken.sol";


contract GovernanceTest is Test {
    Kernel internal kernel;
    Token internal token;
    TallyToken internal tallyToken;
    TimelockController internal timelock;
    Governance internal governance;

    address public deployer;
    address public user1;
    address public user2;
    address public user3;
    UserFactory public userFactory;

    bytes public err;

    function setUp() public {
        userFactory = new UserFactory();
        address[] memory users = userFactory.create(4);
        deployer = users[0]; // deployer is admin/executor by default so it is the address that grants roles
        user1 = users[1];
        user2 = users[2];
        user3 = users[3];

        address[] memory emptyArray = new address[](0);

        // instantiate Kernel, modules, and policies
        vm.startPrank(deployer);
        kernel = new Kernel();
        token = new Token(kernel);
        tallyToken = new TallyToken(kernel);
        timelock = new TimelockController(0, emptyArray, emptyArray, address(0));
        governance = new Governance(kernel, token, timelock);

        // install modules and activate policies
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.ActivatePolicy, address(tallyToken));
        kernel.executeAction(Actions.InstallModule, address(governance));

        // grant COMPTROLLER role to deployer, mint tokens to all except user3
        Role COMPTROLLER = token.COMPTROLLER();
        kernel.grantRole(COMPTROLLER, deployer);
        for (uint256 i; i < (users.length - 1); i++) {
            token.mintTo(users[i], 1);
        }
        
        vm.stopPrank();
    }

    // test GOVRN module was installed properly
    function testInstallGovernanceModule() public {        
        Keycode governanceKeycode = governance.KEYCODE();

        Module installedGovernance = kernel.getModuleForKeycode(governanceKeycode);
        assertEq(address(installedGovernance), address(governance));
        Keycode installedKeycode = kernel.getKeycodeForModule(installedGovernance);
        assertEq(fromKeycode(installedKeycode), fromKeycode(governanceKeycode));
        Keycode addedKeycode = kernel.allKeycodes(1); // TOKEN module occupies first keycode slot
        assertEq(fromKeycode(addedKeycode), fromKeycode(governanceKeycode));
    }

    // ensure proposals made by holders with less tokens than proposalThreshold revert as expected
    function testProposeFailNoVotes() public {
        vm.roll(2);
        uint256 lastBlock = block.number - 1;
        uint256 noVotes = governance.getVotes(user3, lastBlock);
        assertEq(noVotes, 0);
        uint256 vote1 = governance.getVotes(deployer, lastBlock); 
        assertEq(vote1, 1);
        uint256 vote2 = governance.getVotes(user1, lastBlock);
        assertEq(vote2, 1);
        uint256 vote3 = governance.getVotes(user2, lastBlock);
        assertEq(vote3, 1);

        Governance newGovernance = new Governance(kernel, token, timelock);
        address[] memory newModule = new address[](1);
        newModule[0] = address(newGovernance);
        uint256[] memory zero = new uint256[](1);
        zero[0] = 0;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(kernel.executeAction.selector, Actions.InstallModule, address(newGovernance));
        bytes memory error = abi.encodeWithSelector(Governance.Module_NotEnoughVotes.selector);
        
        vm.expectRevert(error);
        vm.prank(user3);
        governance.propose(
            newModule,
            zero,
            data,
            "reinstall module proposal FAIL (revert)"
        );
    }
    
    // test making a proposal to reinstall a module
    function testPropose() public {
        vm.roll(2);
        uint256 lastBlock = block.number - 1;
        uint256 noVotes = governance.getVotes(user3, lastBlock);
        assertEq(noVotes, 0);
        uint256 vote1 = governance.getVotes(deployer, lastBlock); 
        assertEq(vote1, 1);
        uint256 vote2 = governance.getVotes(user1, lastBlock);
        assertEq(vote2, 1);
        uint256 vote3 = governance.getVotes(user2, lastBlock);
        assertEq(vote3, 1);

        Governance newGovernance = new Governance(kernel, token, timelock);
        address[] memory newModule = new address[](1);
        newModule[0] = address(newGovernance);
        uint256[] memory zero = new uint256[](1);
        zero[0] = 0;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(kernel.executeAction.selector, Actions.InstallModule, address(newGovernance));
        vm.prank(user1);
        uint256 firstProposal = governance.propose(
            newModule,
            zero,
            data,
            "reinstall module proposal"
        );

        // assert pending status in this block (since proposal becomes active in next block)
        IGovernor.ProposalState currentState = governance.state(firstProposal);
        assertEq(uint(currentState), uint(IGovernor.ProposalState.Pending));

        // assert votingDelay() and votingPeriod() were added to current block for proposalSnapshot() and proposalDeadline()
        uint256 startingBlock = governance.proposalSnapshot(firstProposal);
        assertEq(startingBlock, block.number);
        uint256 endingBlock = governance.proposalDeadline(firstProposal);
        assertEq(endingBlock, governance.votingPeriod() + block.number);

        // fast forward one block to #3 and assert active status reached
        vm.roll(3);
        IGovernor.ProposalState activeState = governance.state(firstProposal);
        assertEq(uint(activeState), uint(IGovernor.ProposalState.Active));

        // check targets, values, signatures, calldatas were set properly on the proposalId
        (   
            address[] memory targetedNewModule, 
            uint256[] memory zeroValue, 
            string[] memory signatures, // unused parameter
            bytes[] memory targetData
        ) = governance.getActions(firstProposal);
        assertEq(targetedNewModule, newModule);
        assertEq(zeroValue, zero);
        assertEq(targetData[0], data[0]);

        // sample some expected ProposalDetails values
        // checking all return values is unnecessary and contributes to potential overflow of stack depth
        (
            , //uint256 id,
            address proposer,
            , //uint256 eta,
            , //uint256 startBlock,
            , //uint256 endBlock,
            uint256 forVotes,
            , //uint256 againstVotes,
            , //uint256 abstainVotes,
            , //bool canceled,
            bool executed
        ) = governance.proposals(firstProposal);
        assertEq(proposer, user1);
        assertEq(forVotes, 0);
        assertEq(executed, false);

        // fast forward to endBlock + 1 and assert proposal dies with defeated status
        vm.roll(endingBlock + 1);
        IGovernor.ProposalState defeatedState = governance.state(firstProposal);
        assertEq(uint(defeatedState), uint(IGovernor.ProposalState.Defeated));
    }

    // test votes are tabulated correctly whether for, against, or abstention
    function testVotes() public {
        vm.roll(2);
        uint256 lastBlock = block.number - 1;
        uint256 noVotes = governance.getVotes(user3, lastBlock);
        assertEq(noVotes, 0);
        uint256 vote1 = governance.getVotes(deployer, lastBlock); 
        assertEq(vote1, 1);
        uint256 vote2 = governance.getVotes(user1, lastBlock);
        assertEq(vote2, 1);
        uint256 vote3 = governance.getVotes(user2, lastBlock);
        assertEq(vote3, 1);

        // make proposal to be voted on
        Governance newGovernance = new Governance(kernel, token, timelock);
        address[] memory newModule = new address[](1);
        newModule[0] = address(newGovernance);
        uint256[] memory zero = new uint256[](1);
        zero[0] = 0;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(kernel.executeAction.selector, Actions.InstallModule, address(newGovernance));
        vm.prank(user1);
        uint256 firstProposal = governance.propose(
            newModule,
            zero,
            data,
            "reinstall module proposal"
        );

        // fast forward one block to #3 and assert active status reached
        vm.roll(3);
        IGovernor.ProposalState activeState = governance.state(firstProposal);
        assertEq(uint(activeState), uint(IGovernor.ProposalState.Active));

        // ensure users without tokens may not vote
        bytes memory error = abi.encodeWithSelector(Governance.Module_NotEnoughVotes.selector);
        vm.expectRevert(error);
        vm.prank(user3);
        governance.castVote(firstProposal, 0);
        
        // vote as multiple users in separate blocks
        vm.roll(4);
        vm.prank(user1);
        governance.castVote(firstProposal, 1); // 0 == against, 1 == for, 2 == abstain

        bool firstVote = governance.hasVoted(firstProposal, user1);
        assertTrue(firstVote);

        // roll forward 1 block and check weight was added to forVotes inside ProposalDetails values
        vm.roll(5);
        (
            , //uint256 id,
            , //address proposer,
            , //uint256 eta,
            , //uint256 startBlock,
            , //uint256 endBlock,
            uint256 forVotesOne,
            , //uint256 againstVotes,
            , //uint256 abstainVotes,
            , //bool canceled,
              //bool executed
        ) = governance.proposals(firstProposal);
        assertEq(forVotesOne, 1);
        
        // user2 votes against
        vm.roll(6);
        vm.prank(user2);
        governance.castVote(firstProposal, 0);

        bool secondVote = governance.hasVoted(firstProposal, user2);
        assertTrue(secondVote);

        // roll forward 1 block and check weight was added to forVotes inside ProposalDetails values
        vm.roll(7);
        (
            , //uint256 id,
            , //address proposer,
            , //uint256 eta,
            , //uint256 startBlock,
            , //uint256 endBlock,
            uint256 forVotesTwo,
            uint256 againstVotesOne,
            , //uint256 abstainVotes,
            , //bool canceled,
              //bool executed
        ) = governance.proposals(firstProposal);
        assertEq(forVotesTwo, 1);
        assertEq(againstVotesOne, 1);

        // deployer abstains
        vm.roll(8);
        vm.prank(deployer);
        governance.castVote(firstProposal, 2);

        bool thirdVote = governance.hasVoted(firstProposal, deployer);
        assertTrue(thirdVote);

        // roll forward 1 block and check weight was added to forVotes inside ProposalDetails values
        vm.roll(9);
        (
            , //uint256 id,
            , //address proposer,
            , //uint256 eta,
            , //uint256 startBlock,
            , //uint256 endBlock,
            uint256 forVotesThree,
            uint256 againstVotesTwo,
            uint256 abstainVotes,
            , //bool canceled,
              //bool executed
        ) = governance.proposals(firstProposal);
        assertEq(forVotesThree, 1);
        assertEq(againstVotesTwo, 1);
        assertEq(abstainVotes, 1);
    }

    // test execute proposal
    function testExecute() public {
        vm.roll(2);
        uint256 lastBlock = block.number - 1;
        uint256 noVotes = governance.getVotes(user3, lastBlock);
        assertEq(noVotes, 0);
        uint256 vote1 = governance.getVotes(deployer, lastBlock); 
        assertEq(vote1, 1);
        uint256 vote2 = governance.getVotes(user1, lastBlock);
        assertEq(vote2, 1);
        uint256 vote3 = governance.getVotes(user2, lastBlock);
        assertEq(vote3, 1);

        // make proposal to be voted on
        Governance newGovernance = new Governance(kernel, token, timelock);
        address[] memory newModule = new address[](1);
        newModule[0] = address(newGovernance);
        uint256[] memory zero = new uint256[](1);
        zero[0] = 0;
        bytes[] memory data = new bytes[](1);
        data[0] = abi.encodeWithSelector(kernel.executeAction.selector, Actions.InstallModule, address(newGovernance));
        vm.prank(user1);
        uint256 firstProposal = governance.propose(
            newModule,
            zero,
            data,
            "reinstall module proposal"
        );

        // fast forward one block to #3 and assert active status reached
        vm.roll(3);
        IGovernor.ProposalState activeState = governance.state(firstProposal);
        assertEq(uint(activeState), uint(IGovernor.ProposalState.Active));

        address[3] memory users = [deployer, user1, user2];
        for (uint i; i < users.length; i++) {
            vm.prank(users[i]);
         
            governance.castVote(firstProposal, 1);
        }

        // execute proposal /////// note that policy == _executor() so this needs to be changed
        vm.roll(4);
        vm.prank(deployer);
        governance.execute(firstProposal);

        // assert address of new module has been set in kernel via govrn keycode ?
    }
    // proposalSnapshot(), test proposal failure

// test votingDelay, votingPeriod w/reverts
 

// test cancel proposal
}