/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFT {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

contract UnitLondonMarketplace {
    struct NFT {
        address artist;
        address collection;
        uint256 tokenId;
        uint256 price;
    }

    event NFTSold(address collection, uint256 tokenId, address to);
    event HyperMintRegistered(address collection);

    address public owner;
    uint256 public feePercent = 30; // 30%

    NFT[] public listings;
    mapping(bytes32 => uint256) public signs;
    mapping(address => bool) hypermints;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setFeePercent(uint256 newFeePercent) external onlyOwner {
        feePercent = newFeePercent;
    }

    function registerHyperMint(address[] calldata collections) external onlyOwner {
      for (uint256 i; i < collections.length; i++) {
        address collection = collections[i];
        if (!hypermints[collection]) {
          hypermints[collection] = true;
          emit HyperMintRegistered(collection);
        }
      }
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function escapeTokens(address token, uint256 amount) external onlyOwner {
        INFT(token).transferFrom(address(this), owner, amount);
    }

    function listNFT(
        address artist,
        address collection,
        uint256 tokenId,
        uint256 price
    ) external onlyOwner {
        require(INFT(collection).ownerOf(tokenId) == address(this));
        bytes32 sign = keccak256(abi.encodePacked(collection, tokenId));
        require(signs[sign] == 0);
        listings.push(NFT(artist, collection, tokenId, price));
        uint256 listingId = listings.length;
        signs[sign] = listingId;
    }

    function updateListing(
        address collection,
        uint256 tokenId,
        uint256 price
    ) external onlyOwner {
        bytes32 sign = keccak256(abi.encodePacked(collection, tokenId));
        uint256 listingId = signs[sign];
        listings[listingId - 1].price = price;
    }

    function cancelListing(address collection, uint256 tokenId)
        external
        onlyOwner
    {
        bytes32 sign = keccak256(abi.encodePacked(collection, tokenId));
        require(signs[sign] > 0);
        delete signs[sign];
        INFT(collection).transferFrom(address(this), owner, tokenId);
    }

    function buy(address collection, uint256 tokenId) external payable {
        bytes32 sign = keccak256(abi.encodePacked(collection, tokenId));
        uint256 listingId = signs[sign];
        require(signs[sign] > 0);
        require(listings[listingId - 1].price <= msg.value);
        uint256 fee = (msg.value * feePercent) / 100;
        payable(owner).transfer(fee);
        payable(listings[listingId - 1].artist).transfer(msg.value - fee);
        delete signs[sign];
        INFT(collection).transferFrom(address(this), msg.sender, tokenId);
        emit NFTSold(collection, tokenId, msg.sender);
    }

    receive() external payable {}
}