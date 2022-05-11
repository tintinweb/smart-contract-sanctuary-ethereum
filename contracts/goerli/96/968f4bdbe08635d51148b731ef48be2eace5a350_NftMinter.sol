// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";

contract NftMinter is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public totalSupply;
    uint256 public pricePerNft;
    address private _creatorAddress;
    string private _baseUri;
    bool private _baseUriSettable = true;

    event TokensMinted(uint256 numTokensMinted, string clientInfo);

    /// Creates a new NftMinter.
    /// @param name_ the name of the NFT collection.
    /// @param symbol_ the symbol of the NFT collection.
    /// @param totalItems_ the total number of items in the collection.
    /// @param pricePerNft_ the price per NFT.
    /// @param baseUri_ NFT metadata should be located at baseUri_/XXX where XXX is the tokenId.
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalItems_,
        uint256 pricePerNft_,
        string memory baseUri_
    ) ERC721(name_, symbol_) {
        _creatorAddress = msg.sender;
        totalSupply = totalItems_;
        pricePerNft = pricePerNft_;
        _baseUri = baseUri_;
    }

    function mint(uint256 numTokensToMint, string memory clientInfo)
        public
        payable
        returns (uint256[] memory)
    {
        uint256 currentPayment = computeCost(numTokensToMint);
        require(msg.value == currentPayment, "Invalid payment amount.");
        uint256[] memory newItemIds = new uint256[](numTokensToMint);
        uint256 numTokensMinted = 0;
        for (uint256 i = 0; i < numTokensToMint; ++i) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            require(newItemId <= totalSupply, "Can't mint that many NFTs.");

            super._mint(msg.sender, newItemId);
            newItemIds[i] = newItemId;
            numTokensMinted++;
        }
        emit TokensMinted(numTokensMinted, clientInfo);

        return newItemIds;
    }

    function remainingMintableTokens() public view returns (uint256) {
        return totalSupply - _tokenIds.current();
    }

    function ownerWithdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    }

    function setBaseUri(string memory baseUri) public onlyOwner {
        require(_baseUriSettable, "URIs are frozen.");
        _baseUri = baseUri;
    }

    function freezeMetadata() public onlyOwner {
        require(_baseUriSettable, "URIs are frozen.");
        _baseUriSettable = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function computeCost(uint256 numTokensToMint)
        public
        view
        returns (uint256)
    {
        return numTokensToMint * pricePerNft;
    }
}