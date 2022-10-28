// SPDX-License-Identifier: AGPL-3.0-only

// [GOVRN] The Governance Module inherits the OpenZeppelin implementation of Governor.sol that handles proposals and voting.
// This module restricts all access save for select permissioned functions from the Tally policy
// @notice Voting power is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

import { Governor } from "openzeppelin-contracts/governance/Governor.sol";
import { GovernorVotes } from "openzeppelin-contracts/governance/extensions/GovernorVotes.sol";
import "openzeppelin-contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "openzeppelin-contracts/governance/extensions/GovernorTimelockControl.sol";
import "openzeppelin-contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import { IVotes } from "openzeppelin-contracts/governance/utils/IVotes.sol";
import { Kernel, Module, Keycode, Role, Policy } from "src/Kernel.sol";

contract Governance is Module, Governor, GovernorVotes, GovernorCompatibilityBravo, GovernorVotesQuorumFraction, GovernorTimelockControl {

    error Module_OnlyGovExecutor(address govExecutor);
    error Module_NotEnoughVotes();

    constructor(Kernel kernel_, IVotes _token, TimelockController _timelock) Module(kernel_) Governor("Governance") GovernorVotes(_token) GovernorVotesQuorumFraction(4) GovernorTimelockControl(_timelock) {}

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
    // @dev Set to instantly enable voting without delay
    function votingDelay() public view override returns (uint256) {
        return 0;
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

    function quorum(uint256 blockNumber) public pure override(IGovernor, GovernorVotesQuorumFraction) returns (uint256) {
        return 3;
    }

    // @notice Returns the delegated balance of an account
    // @param Since only current vote weight is desired, blockNumber is discarded and getPastVotes() is circumvented
    function getVotes(address account, uint256 blockNumber) public view override(IGovernor, Governor/*, GovernorVotes*/) returns (uint256) {
        return token.getVotes(account);
    }

    /* 
    /// Governor Functions ///
    */

    function state(uint256 proposalId) public view override(Governor, IGovernor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId);
    }

    // @param targets refers to the addresses to be called
    // @param values refers to the call.value to provide to each address
    // @param calldatas refers to the call.data to provide to each contract
    // @param description refers to a proposal description alongside the execution
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256 proposalId) {
        if (getVotes(msg.sender, block.number) < proposalThreshold()) { revert Module_NotEnoughVotes(); }
        return super.propose(targets, values, calldatas, description);
    }
    
    // @notice Execution of proposals is open to anyone and everyone at the policy level to prevent governance stalling
    // @param Only the TallyGovernor policy is granted the 'executor' role ///// maybe timelock?????
    // function execute(uint256 proposalId) public override {
        // address govExecutor = _executor();
        // if (msg.sender != govExecutor) revert Module_OnlyGovExecutor(govExecutor);
    // }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
            );
    }
    
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        address govExecutor = _executor();
        if (msg.sender != govExecutor) revert Module_OnlyGovExecutor(govExecutor);

        return super._cancel(targets, values, calldatas, descriptionHash);
    }
    
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        Policy policy = kernel.moduleDependents(KEYCODE(), 0);
        return address(policy);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(Governor, IERC165, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


    //todo
    /*Governance function ideas:
      -setProtocolFee() setPayoutAddress() 
      // kernel struct actions: 
      changeAdmin() changeExecutor() installModule() upgradeModule() activatePolicy() deactivatePolicy() newGovernanceModule()
    */
}

