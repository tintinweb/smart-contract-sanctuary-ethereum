// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IImbuedNFT.sol";

/// Minter contract of Imbued Art tokens.
/// This contract allows any holder of an Imbued Art token (address
/// `0x000001e1b2b5f9825f4d50bd4906aff2f298af4e`) to mint one new Imbued NFT for
/// each they already own. The contract allows tokens of ID up to
/// `maxWhitelistId` to mint new tokens.
/// The price per token is `whitelistPrice`.
/// The owner of the minter account may mint tokens at no cost (they also are
/// priviliged to withdraw any funds deposited into the account, so this only
/// cuts out an extra transaction).
/// However, note that the Imbued Art contract restricts even the admin on what can be minted:
/// The highest tokenId that can ever be minted is 699, and an admin can't mint
/// a token with an id that already exists.
contract ImbuedMintV2 is Ownable {
    IImbuedNFT immutable public NFT;

    uint16 public maxWhiteListId = 99;
    uint16 public nextId = 101;
    uint16 public maxId = 199;
    uint256 public whitelistPrice = 0.05 ether;

    mapping (uint256 => bool) public tokenid2claimed; // token ids that are claimed.

    constructor(uint16 _maxWhiteListId, uint16 _startId, uint16 _maxId, uint256 _whitelistPrice, IImbuedNFT nft) {
        maxWhiteListId = _maxWhiteListId;
        nextId = _startId;
        maxId = _maxId;
        whitelistPrice = _whitelistPrice;
        NFT = nft;
    }

    /// Minting using whitelisted tokens.  You pass a list of token ids under
    /// your own, pay `whitelistPrice` * `tokenIds.length`, and receive
    /// `tokenIds.length` newly minted tokens.
    /// @param tokenIds a list of tokens
    function mint(uint16[] calldata tokenIds) external payable {
        uint8 amount = uint8(tokenIds.length);
        require(msg.value == amount * whitelistPrice, "wrong amount of ether sent");

        unchecked {
            for (uint256 i = 0; i < amount; i++) {
                uint256 id = tokenIds[i];
                require(id <= maxWhiteListId, "not a whitelisted token id");
                require(!tokenid2claimed[id], "token already used for claim");
                address tokenOwner = NFT.ownerOf(id);
                require(msg.sender == tokenOwner , "sender is not token owner");
                tokenid2claimed[id] = true;
            }
        }
        _mint(msg.sender, amount);
    }

    // only owner

    /// (Admin only) Admin can mint without paying fee, because they are allowed to withdraw anyway.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param amount the number of tokens to mint, starting with id `nextId()`.
    function adminMintAmount(address recipient, uint8 amount) external payable onlyOwner() {
        _mint(recipient, amount);
    }

    /// (Admin only) Can mint *any* token ID. Intended foremost for minting
    /// major versions for the artworks.
    /// @param recipient what address should be sent the new token, must be an
    ///        EOA or contract able to receive ERC721s.
    /// @param tokenId which id to mint, may not be a previously minted one.
    function adminMintSpecific(address recipient, uint256 tokenId) external payable onlyOwner() {
        NFT.mint(recipient, tokenId);
    }

    /// (Admin only) Set the highest token id which may be used for a whitelist mint.
    /// @param newMaxWhitelistId the new maximum token id that is whitelisted.
    function setMaxWhitelistId(uint16 newMaxWhitelistId) external payable onlyOwner() {
        maxWhiteListId = newMaxWhitelistId;
    }

    /// (Admin only) Set the next id that will be minted by whitelisters or
    /// `adminMintAmount`.  If this id has already been minted, all minting
    /// except `adminMintSpecific` will be impossible.
    /// @param newNextId the next id that will be minted.
    function setNextId(uint16 newNextId) external payable onlyOwner() {
        nextId = newNextId;
    }

    /// (Admin only) Set the maximum mintable ID (for whitelist minters).
    /// @param newMaxId the new maximum id that can be whitelist minted (inclusive).
    function setMaxId(uint16 newMaxId) external payable onlyOwner() {
        maxId = newMaxId;
    }
    
    /// (Admin only) Set the price per token for whitelisted minters
    /// @param newPrice the new price in wei.
    function setWhitelistPrice(uint256 newPrice) external payable onlyOwner() {
        whitelistPrice = newPrice;
    }

    /// (Admin only) Withdraw the entire contract balance to the recipient address.
    /// @param recipient where to send the ether balance.
    function withdrawAll(address payable recipient) external payable onlyOwner() {
        recipient.call{value: address(this).balance}("");
    }

    /// (Admin only) self-destruct the minting contract.
    /// @param recipient where to send the ether balance.
    function kill(address payable recipient) external payable onlyOwner() {
        selfdestruct(recipient);
    }

    // internal

    // Reentrancy protection: not needed. The only variable that has not yet
    // been updated is nextId.  If you try to mint again using re-entrancy, the
    // mint itself will fail.
    function _mint(address recipient, uint8 amount) internal {
        uint256 nextCache = nextId;
        unchecked {
            uint256 newNext = nextCache + amount;
            require(newNext - 1 <= maxId, "can't mint that many");
            for (uint256 i = 0; i < amount; i++) {
                require((nextCache + i) % 100 != 0, "minting a major token");
                NFT.mint(recipient, nextCache + i); // reentrancy danger. Handled by fact that same ID can't be minted twice.
            }
            nextId = uint16(newNext);
        }
    }
}