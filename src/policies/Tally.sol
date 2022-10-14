// SPDX-License-Identifier: MIT

// The Tally Policy inherits the OpenZeppelin IGovernor.sol interface to conform to Tally.xyz frontend API.
// This policy routes governance decisions through the [GOVRN] module which inherits OpenZeppelin's Governor.sol to provide an external-facing API that conforms to Tally.xyz's frontend
// @notice Voting weight calculation is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

import { IGovernor } from "openzeppelin-contracts/governance/IGovernor.sol";
import "../Kernel.sol";
import "../modules/GOVRN.sol";

contract Tally is Policy /*, IGovernor*/ {

    /// **Function signatures required for compatibility w/ Tally** ///
    /* 
        function votingDelay() public view virtual returns (uint256) {
            return governance.votingDelay();
        }
        function votingPeriod() public view virtual returns (uint256) {
            return governance.votingPeriod();
        }
        function quorum(uint256 blockNumber) public view virtual returns (uint256) {
            return governance.quorum(blockNumber);
        }
        function proposalThreshold() public view virtual returns (uint256) {
            return governance.proposalThreshold();
        }
        function state(uint256 proposalId) public view virtual override returns (ProposalState) {
            return governance.state(proposalId);
        }

        function getVotes(
            address account, 
            uint256 blockNumber
        ) public view virtual returns (uint256);

        function propose(
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            string memory description
        ) public virtual returns (uint256 proposalId) {
            emit ProposalCreated(
                uint256 proposalId,
                address proposer,
                address[] targets,
                uint256[] values,
                string[] signatures,
                bytes[] calldatas,
                uint256 startBlock,
                uint256 endBlock,
                string description
            )
        }

        function execute(
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) public payable virtual returns (uint256 proposalId) {
            emit ProposalExecuted(uint256 proposalId)
        }

        function castVote(
            uint256 proposalId, 
            uint8 support
        ) public virtual returns (uint256 balance) {
            emit VoteCast(
                address indexed voter, 
                uint256 proposalId, 
                uint8 support, 
                uint256 weight, 
                string reason
            )
        }

        function castVoteWithReason(
            uint256 proposalId,
            uint8 support,
            string calldata reason
        ) public virtual returns (uint256 balance) {
            emit VoteCast(
                address indexed voter, 
                uint256 proposalId, 
                uint8 support, 
                uint256 weight, 
                string reason
            )
        }

        function castVoteBySig(
            uint256 proposalId,
            uint8 support,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) public virtual returns (uint256 balance) {
            emit VoteCast(
                address indexed voter, 
                uint256 proposalId, 
                uint8 support, 
                uint256 weight, 
                string reason
            )
        }
    */ 

}