// SPDX-License-Identifier: MIT

// The Tally Policy inherits the OpenZeppelin IGovernor.sol interface to conform to Tally.xyz frontend API.
// This policy routes governance decisions through the [GOVRN] module which inherits OpenZeppelin's Governor.sol to provide an external-facing API that conforms to Tally.xyz's frontend
// @notice Voting weight calculation is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

import { IGovernor } from "openzeppelin-contracts/governance/IGovernor.sol";
import { toKeycode } from "../utils/KernelUtils.sol";
import "../Kernel.sol";
import "../modules/GOVRN.sol";

contract Tally is Policy /*, IGovernor*/ {

    // set by a call from the Kernel to configureDependencies() when this Policy is enabled in the Kernel registry
    Governance governance;
    
    constructor(Kernel kernel_) Policy(kernel_) {}

    // @notice Required to initialize a Policy
    // @dev Sets permitted function signatures, module keycode, and address in the Kernel
    function requestPermissions() external view override onlyKernel returns (Permissions[] memory requests) {
        // requests = new Permissions[](11);
        // requests[0] = Permissions(toKeycode("GOVRN"), governance.votingDelay.selector);
        // requests[1] = Permissions(toKeycode("GOVRN"), governance.votingPeriod.selector);
        // requests[2] = Permissions(toKeycode("GOVRN"), governance.quorum.selector);
        // requests[3] = Permissions(toKeycode("GOVRN"), governance.proposalThreshold.selector);
        // requests[4] = Permissions(toKeycode("GOVRN"), governance.state.selector);
        // requests[5] = Permissions(toKeycode("GOVRN"), governance.getVotes.selector);
        // requests[6] = Permissions(toKeycode("GOVRN"), governance.propose.selector);
        // requests[7] = Permissions(toKeycode("GOVRN"), governance.execute.selector);
        // requests[8] = Permissions(toKeycode("GOVRN"), governance.castVote.selector);
        // requests[9] = Permissions(toKeycode("GOVRN"), governance.castVoteWithReason.selector);
        // requests[10] = Permissions(toKeycode("GOVRN"), governance.castVoteBySig.selector);
    }

    // @notice Required to initialize a Policy
    // @dev Sets various Module dependencies via keycodes for a Policy to call on
    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        Keycode governanceKeycode = toKeycode("GOVRN");
        dependencies = new Keycode[](1); // + tallytoken nft contract?
        dependencies[0] = governanceKeycode;
        // set governance in storage to dependency
        governance = Governance(getModuleAddress(governanceKeycode));
    }


    /*
    /// External-facing API via GOVRN module backend ///
    */




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
        ) public view virtual returns (uint256) {
            return governance.getVotes(account, blockNumber);
        }

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
            );

            return governance.propose(targets, values, calldatas, description);
        }

        function execute(
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 descriptionHash
        ) public payable virtual returns (uint256 proposalId) {
            emit ProposalExecuted(uint256 proposalId);

            return governance.execute(targets, values, calldatas, descriptionHash);
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
            );

            return governance.castVote(proposalId, support);
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
            );

            return governance.castVoteWithReason(proposalId, support, reason);
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
            );

            return governance.castVoteBySig(proposalId, support, v, r, s);
        }
    */ 

}