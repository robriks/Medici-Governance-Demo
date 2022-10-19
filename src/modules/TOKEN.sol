// SPDX-License-Identifier: MIT

// [TOKEN] The Token Module is an ERC721 non-fungible token that represents voting power in the network.
// @notice Handling of actual voting logic is outsourced to the Governance module

pragma solidity ^0.8.15;

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Votes.sol";
import "openzeppelin-contracts/utils/Counters.sol";
import "src/utils/KernelUtils.sol";
import { Kernel, Module, Keycode, Role, Policy } from "src/Kernel.sol";

error Token_TransferDisabled();
error Token_OnlyKernelAdmin();

contract Token is Module, ERC721Votes {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    // @notice Comptroller role is a Medici team member who wields the power to mint governance tokens and enable/disable transfers
    // @dev Bear in mind that only lowercase string characters may be wrapped into a role
    Role public constant COMPTROLLER = Role.wrap("comptroller"); 
    
    constructor(Kernel kernel_) Module(kernel_) ERC721("Medici Governance Token", "Token") EIP712("Medici Governance Token", "0.1") {}

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
        // set initial supply, tokenURI
        // These 'constructor' configurations may be decided by DAO/team when upgrading this module
        // uint initialTokenSupply = ????;
        // _setTokenURI(????) 
        
        // optional mintTo() call to initialize some governance tokens to Medici team/DAO
        // keep in mind this will alter some test results if enabled
        // mintTo(tx.origin, someAmount);
    }

    //todo finish implementing tokenuri logic after consulting with medici on format/content
    //todo add _setTokenURI() function to give Medici and the DAO a way to change tokenURI if needed
    function tokenURI(uint256 id) public view override returns (string memory) {
        return "hello world";
    }

    // @notice TransferFrom is disabled to start
    // @notice This function may only be called from the permissioned() Policy
    // @dev If condition ensures the permissioned policy possesses necessary approvals
    // @dev Approval is safe here as the permissioned policy checks caller is token owner
    function transferFrom(
        address from, 
        address to, 
        uint256 id
    ) permissioned public override {
        // approval prevents issues in case a user habitually revokes approval or manually approves another address
        Policy policy = kernel.moduleDependents(KEYCODE(), 0);
        if (getApproved(id) != address(policy)) {
            _approve(address(policy), id);
        }

        super.transferFrom(from, to, id);
    }

    // @notice SafeTransferFrom is disabled to start
    // @notice This function may only be called from the permissioned() Policy
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) permissioned public override {
        // ensure the permissioned policy possesses necessary approvals
        // this prevents issues in case a user habitually revokes approval or manually approves another address
        Policy policy = kernel.moduleDependents(KEYCODE(), 0);
        if (getApproved(id) != address(policy)) {
            _approve(address(policy), id);
        }

        super.safeTransferFrom(from, to, id);
    }

    // @notice Function for Medici community to mint governance NFTs
    // @dev Solmate's _safeMint() is chosen here in the mint logic to prevent unsafe smart contract minters
    // @dev The policy contract must be approved for all minted tokens so that it may perform transfers
    function mint() public {
        _tokenId.increment();
        uint256 currentId = _tokenId.current();

        _safeMint(msg.sender, currentId);

        Policy policy = kernel.moduleDependents(KEYCODE(), 0);
        _approve(address(policy), currentId); 
    }

    // @notice Admin-chosen users with comptroller role retain the ability to empower governors with new tokens
    // @notice COMPTROLLER role is intended only for trustworthy members of Medici team
    // @dev onlyRole() modifier ensures only addresses granted COMPTROLLER role by Medici team may mint
    // @dev The policy contract must be approved for all minted tokens so that it may perform transfers
    function mintTo(address to, uint256 amount) public onlyRole(COMPTROLLER) {        
        for (uint256 i; i < amount; i++) {
            _tokenId.increment();
            uint256 currentId = _tokenId.current();

            _safeMint(to,currentId);
            Policy policy = kernel.moduleDependents(KEYCODE(), 0);
            _approve(address(policy), currentId);
        }
    }
}
