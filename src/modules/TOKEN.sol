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
error Token_NotEnoughTokens();

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
    }

    //todo finish implementing tokenuri logic after consulting with medici on format/content
    //todo add _setTokenURI() function to give Medici and the DAO a way to change tokenURI if needed
    function tokenURI(uint256 id) public view override returns (string memory) {
        // placeholder NFT metadata that I put on arweave for fun
        return "ar://VQkFO7gGhsZaC3SdbkzPoiOe_Z1NrqZajsqk0y0DTWo";
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
    // @dev Votes are delegated to the minter by default and may be redelegated at any time
    function mint(address account) permissioned public {
        _tokenId.increment();
        uint256 currentId = _tokenId.current();

        _safeMint(account, currentId);

        _approve(msg.sender, currentId);
        _delegate(account, account);
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
            _delegate(to, to);
    }

    // @notice This function provides for redelegation via TallyToken policy.
    // @notice Each token holder must delegate their balance to an address that will vote based on its token weight
    // @dev Redelegation from the policy means the caller logic of the parent function needs to be overidden
    // @dev In this context tx.origin is never used for authorization and will only ever be users interacting with TallyToken policy
    function delegate(address delegatee) permissioned public override {
        // tx.origin here is safe as it is _never_ used for authentication and cannot be used for phishing vectors
        address account = tx.origin;
        if (balanceOf(account) == 0) {
            revert Token_NotEnoughTokens();
        }
        _delegate(account, delegatee);
    }
}
