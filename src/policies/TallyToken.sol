// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../Kernel.sol";
import "../modules/TOKEN.sol";
import { toKeycode } from "../utils/KernelUtils.sol";

// Currently the TallyToken policy also handles TOKEN module user-facing logic, which in the future may need to be offloaded to a separate token-specific contract

contract TallyToken is Policy {

    // set by a call from the Kernel to configureDependencies() when this Policy is enabled in the Kernel registry
    Token token;

    // @notice Boolean for Medici admins to enable/disable transfer() and transferFrom()
    bool public transfersAllowed;

    modifier transfersEnabled() {
        if (!transfersAllowed) {
            revert Token_TransferDisabled();
        }
        _;
    }

    constructor(Kernel kernel_) Policy(kernel_) {}
    
    // @notice Required to initialize a Policy
    // @dev Sets permitted function signatures, module keycode, and address in the Kernel
    function requestPermissions() external view override onlyKernel returns (Permissions[] memory requests) {
        requests = new Permissions[](3);
        requests[0] = Permissions(toKeycode("TOKEN"), Token.transfer.selector);
        requests[1] = Permissions(toKeycode("TOKEN"), Token.transferFrom.selector);
        requests[2] = Permissions(toKeycode("TOKEN"), Token.mintTo.selector);
    }

    // @notice Required to initialized a Policy
    // @dev Sets various Module dependencies via keycodes for a Policy to call on
    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        Keycode tokenKeycode = toKeycode("TOKEN");
        dependencies = new Keycode[](1);
        dependencies[0] = tokenKeycode;
        // set token in storage to dependency
        token = Token(getModuleAddress(tokenKeycode));
    }

    /*
    /// External-facing API via TOKEN module backend ///
    */

    // @notice Function to enable transfers by flipping transfersEnabled boolean
    // @dev This function may only be called by Medici team admins to enable/disable transfers at time of their discretion
    function toggleTransfersAllowed() external onlyRole(token.COMPTROLLER()) {
        transfersAllowed = !transfersAllowed;
    }

    // @notice Function to send tokens
    // @dev Access control and Medici team enabling/disabling of transfers handled on backend
    function transfer(address to, uint256 amount) public transfersEnabled {
        token.transfer(to, amount);
    }

    // @notice Function for Medici contracts to send tokens on behalf of users
    // @dev Access control and Medici team enabling/disabling of transferFrom handled on backend
    function transferFrom(
        address from, 
        address to, 
        uint256 amount) public transfersEnabled {
            token.transferFrom(from, to, amount);
    }

    // @notice delegation function todo
    function delegate(address to) external {
        //todo
        // require balanceOf(msg.sender) > certain threshold;
        // calculate token vote weight via Governor.sol
        // for simplicity's sake, delegate entire balance of msg.sender
    }
}