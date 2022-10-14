// SPDX-License-Identifier: AGPL-3.0-only

// [GOVRN] The Governor Module inherits the OpenZeppelin implementation of Governor.sol that handles proposals and voting.
// This module restricts all access save for select permissioned functions from the Tally policy
// @notice Voting power is outsourced to the [TOKEN] module

pragma solidity ^0.8.15;

// does the module need to inherit governor or is it enough to inherit Governor.sol in the external-facing policy?
import { GovernorVotes } from "openzeppelin-contracts/governance/extensions/GovernorVotes.sol";
import { Kernel, Module, Keycode } from "src/Kernel.sol";

contract Governance is Module /*, GovernorVotes */ {
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
    
    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 3;
    }

    function votingDelay() public view override(IGovernor /*, GovernorSettings */) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor /*, GovernorSettings */) returns (uint256) {
        return super.votingPeriod();
    }

    function state(uint256 proposalId) public view override(IGovernor) returns (ProposalState) {
        return super.state(proposalId);
    }

    //function propose()
    //function proposalThreshold()
    //function _execute()
    //function _cancel()
    //function _executor()
    //function supportsInterface()
    
    //todo
    /*Governance function ideas:
      -setProtocolFee() setPayoutAddress() 
      // kernel struct actions: 
      changeAdmin() changeExecutor() installModule() upgradeModule() activatePolicy() deactivatePolicy() newGovernanceModule()
    */
}

