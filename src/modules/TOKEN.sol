// SPDX-License-Identifier: MIT

// [VOTES] The Votes Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import "src/utils/KernelUtils.sol";
import { Kernel, Module, Keycode, Role } from "src/Kernel.sol";

error Token_TransferDisabled();
error Token_OnlyKernelAdmin();

contract Token is Module, ERC20 {

    // @notice Comptroller role is a Medici team member who wields the power to mint governance tokens and enable/disable transfers
    Role public constant COMPTROLLER = Role.wrap("comptroller"); 
    
    constructor(Kernel kernel_) Module(kernel_) ERC20("Governance Token", "Token", 6) {}

    // @notice Returns keycode for Policy/Kernel management
    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("TOKEN");
    }

    // @notice Returns release version
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        // alpha version 0.1 
        return (0, 1);
    }

    // @notice Constructoresque function to initialize module
    // @dev Should only be called once by the Kernel when installed. Does not need a check for this as Kernel rejects reinstallation
    function INIT() external override onlyKernel {
        // arbitrary initial supply to be sent to executor. Can be decided by DAO/team when upgrading this module
        uint initialTokenSupply = 1000; 
        // tx.origin is safe here as it will only ever == executor
        mintTo(tx.origin, initialTokenSupply);
    }

    /*
    /// Policy interface ///
    */

    // @notice Transfers are disabled to start
    // @notice This function may only be called from the permissioned() Policy
    function transfer(
        address to, 
        uint256 amount
        ) permissioned public override returns (bool success) {
        success = super.transfer(to, amount);
    }

    // @notice TransferFrom is disabled to start
    // @notice This function may only be called from the permissioned() Policy
    function transferFrom(
        address from, 
        address to, 
        uint256 amount
    ) permissioned public override returns (bool success) {
        success = super.transferFrom(from, to, amount);
    }

    // @notice Admin-chosen users with comptroller role retain the ability to empower governors with new tokens
    // @dev onlyRole() modifier ensures only addresses granted COMPTROLLER role by Medici team may mint
    // @param COMPTROLLER role is intended only for trustworthy members of Medici team
    function mintTo(address to, uint256 amount) public onlyRole(COMPTROLLER) {
        _mint(to, amount);
    }

    //todo implement delegate function
    // then give Tally policy a way for user to delegate
}