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

        // assert pending status
        IGovernor.ProposalState currentState = governance.state(firstProposal);
        assertEq(uint(currentState), uint(IGovernor.ProposalState.Pending));

        // assert proposalSnapshot(firstProposal)
    }

    // test voting, assert hasVoted(), proposalSnapshot(), test proposal failure

// test votingDelay, votingPeriod w/reverts

// test vote on proposal w/ state()

// test execute proposal w/ state()

// test cancel proposal
}