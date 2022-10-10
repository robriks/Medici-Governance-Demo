// SPDX-License-Identifier: AGPL-3.0-only

// [GOVRN] The Governor Module inherits the OpenZeppelin implementation of Governor.sol that handles proposals and voting.
// @notice Voting power is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

// does the module need to inherit governor or is it enough to inherit Governor.sol in the external-facing policy?
// import { Governor } from "openzeppelin/contracts/governance/Governor.sol";
import { Kernel, Module, Keycode } from "src/Kernel.sol";

contract Governance is Module /*, Governor*/ {
    // todo
    // install governor
    // figure out how governor reads token holder weight
    // figure out how token weight affects voting
    // discern proposal procedure
    // ask what kind of gating Medici would like:
    // - admins / community
    // - proposal permissions (minimum token weight)
    // - voting period length

    constructor(Kernel kernel_) Module(kernel_) {}

    // @notice Returns keycode for Policy/Kernel management
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("GOVRN");
    }

    // @notice Returns release version
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        // alpha version 0.1 
        return (0, 1);
    }    
    
    // @notice Section below lists functions and events that need to be overridden to use Tally frontend

    /// **Function signatures required for compatibility w/ Tally** ///
    /* 
        function votingDelay() public view virtual returns (uint256);
        function votingPeriod() public view virtual returns (uint256);
        function quorum(uint256 blockNumber) public view virtual returns (uint256);
        function proposalThreshold() public view virtual returns (uint256);
        function state(uint256 proposalId) public view virtual override returns (ProposalState);

        function getVotes(
            address account, 
            uint256 blockNumber
        ) public view virtual returns (uint256);

        function propose(
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) public virtual returns (uint256 proposalId);

        function execute(
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) public payable virtual returns (uint256 proposalId);

        function castVote(
            uint256 proposalId, 
            uint8 support
        ) public virtual returns (uint256 balance);

        function castVoteWithReason(
            uint256 proposalId,
            uint8 support,
            string calldata reason
        ) public virtual returns (uint256 balance);

        function castVoteBySig(
            uint256 proposalId,
            uint8 support,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) public virtual returns (uint256 balance);
    */ 


    /// **Event signatures required for compatibility w/ Tally**///
    /*
        event ProposalCreated(
            uint256 proposalId,
            address proposer,
            address[] targets,
            uint256[] values,
            string[] signatures,
            bytes[] calldatas,
            uint256 startBlock,
            uint256 endBlock,
            string description
        );

        event ProposalCanceled(uint256 proposalId);
        event ProposalExecuted(uint256 proposalId);

        event VoteCast(
            address indexed voter, 
            uint256 proposalId, 
            uint8 support, 
            uint256 weight, 
            string reason
        );
    */
}

