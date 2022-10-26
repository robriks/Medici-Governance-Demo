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

    // test making a proposal
    function testPropose() public {
        uint256 lastBlock = block.number - 1;
        uint256 noVotes = governance.getVotes(user3, lastBlock);
        assertEq(noVotes, 0);
        uint256 vote1 = token.getVotes(deployer); // what's going on here??
        assertEq(vote1, 1);
        // uint256 vote2 = token.getVotes(user1, lastBlock);
        // assertEq(vote2, 1);
        // uint256 vote3 = token.getVotes(user2, lastBlock);
        // assertEq(vote3, 1);
    }


// test _executor() in  returns kernel address
  // can this work with a timelock? (timelock is usually set to executor)

// test votingDelay, votingPeriod w/reverts

// test make proposal w/ proposalThreshold reverts, state()


// test vote on proposal w/ state()

// test execute proposal w/ state()

// test cancel proposal
}