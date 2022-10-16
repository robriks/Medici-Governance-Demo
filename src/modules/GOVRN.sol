// SPDX-License-Identifier: AGPL-3.0-only

// [GOVRN] The Governance Module inherits the OpenZeppelin implementation of Governor.sol that handles proposals and voting.
// This module restricts all access save for select permissioned functions from the Tally policy
// @notice Voting power is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

import { Governor } from "openzeppelin-contracts/governance/Governor.sol";
import { GovernorVotes } from "openzeppelin-contracts/governance/extensions/GovernorVotes.sol";
import { IVotes } from "openzeppelin-contracts/governance/utils/IVotes.sol";
import { Kernel, Module, Keycode } from "src/Kernel.sol";

contract Governance is Module, Governor, GovernorVotes {

    constructor(Kernel kernel_, IVotes _token) Module(kernel_) Governor("Governance") GovernorVotes(_token) {}

    // @notice Returns keycode for Policy/Kernel management
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("GOVRN");
    }

    // @notice Returns release version
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        // alpha version 0.1 
        return (0, 1);
    }

    /*
    /// Governor Configurations ///
    */

    // @notice Return the delay, in number of blocks, between proposal creation and the vote start.
    // @dev Set to one week's worth of blocks
    function votingDelay() public view override returns (uint256) {
        return 50400;
    }

    // @notice Return the period, in number of blocks, between the vote start and the vote end.
    // @dev Set to one week's worth of blocks
    function votingPeriod() public view override returns (uint256) {
        return 50400;
    }

    // @notice The number of votes required in order for a voter to make governance proposals
    function proposalThreshold() public view override returns (uint256) {
        return 1;
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 3;
    }

    function _quorumReached(uint256 proposalId) internal view override returns (bool) {
        /* if (_countVotes(uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params)
        > quorum(block.current)) 
        return false*/
        
        // else
        return true;
    }

    function _voteSucceeded(uint256 proposalId) internal view override returns (bool) {
        // if (_quorumReached && state(proposalId) == ProposalState.Active && probably other things)
        //todo


        return true;
    }

    // @notice The configuration of voting inputs and quorum counting
    // @dev Bravo support means: 0 == for, 1 == against, 2 == abstain
    // @dev Bravo quorum means only For votes (not abstentions) are counted towards quorum
    function COUNTING_MODE() public pure override returns (string memory) {
        return "support=bravo&quorum=bravo";
    }

    /* 
    /// Token Dependency functions
    */

    // @notice Returns whether 'account' has cast a vote on 'proposalId'
    function hasVoted(uint256 proposalId, address account) public view override returns (bool) {
        // if (account has voted -how to check this/??) {}
        return true;
    }

    // @notice Calculate vote counts from Medici ERC721 token weights
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal override {
        
        
        uint a = 1;
        //todo
    }

    /* 
    /// Governor Functions ///
    */

    function state(uint256 proposalId) public view override returns (ProposalState) {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }
    
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }
    
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }
    
    function _executor() internal view override returns (address) {
        return super._executor();
    }
    
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    //todo
    /*Governance function ideas:
      -setProtocolFee() setPayoutAddress() 
      // kernel struct actions: 
      changeAdmin() changeExecutor() installModule() upgradeModule() activatePolicy() deactivatePolicy() newGovernanceModule()
    */
}

