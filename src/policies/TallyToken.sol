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

    error OwnerMismatch(address owner);

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
        requests = new Permissions[](2);
        requests[0] = Permissions(toKeycode("TOKEN"), Token.transferFrom.selector);
        requests[1] = Permissions(toKeycode("TOKEN"), Token.safeTransferFrom.selector);
    }

    // @notice Required to initialize a Policy
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

    // @notice Function for user-facing transfers via this policy contract
    // @dev Call to approve() is necessary here as a result of a msg.sender check in the backend module when called by this frontend policy
    function transferFrom(
        address from, 
        address to, 
        uint256 id) public transfersEnabled {
            address tokenOwner = token.ownerOf(id);
            if (tokenOwner != msg.sender) {
                revert OwnerMismatch(tokenOwner);
            }

            token.transferFrom(from, to, id);
    }

    // @notice Function for Medici contracts to send tokens on behalf of users with additional ERC721TokenReceiver check
    // @dev Access control and Medici team enabling/disabling of safeTransferFrom handled on backend
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id) public transfersEnabled {
            address tokenOwner = token.ownerOf(id);
            if (tokenOwner != msg.sender) {
                revert OwnerMismatch(tokenOwner);
            }

            token.safeTransferFrom(from, to, id);
    }
}