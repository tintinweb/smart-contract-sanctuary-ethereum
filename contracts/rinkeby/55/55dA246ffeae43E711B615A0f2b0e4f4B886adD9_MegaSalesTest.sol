/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external returns (bool);
}

contract MegaSalesTest {
  address public owner;
  address public nft;
  uint256[] public inventory;
  uint256 public minted;
  uint256 public price;
  bool public initialized;

  modifier onlyOwner() {
    require(msg.sender == owner, "MegaSales: no owner role");
    _;
  }

  event Purchase(uint256 tokenId, address owner);

  constructor() {
    owner = msg.sender;
    initialized = false;
  }

  // View Functions
  function info() public view returns (uint256 _minted, uint256 _total, uint256 _price) {
    uint256 total = inventory.length;
    return (minted, total, price);
  }

  // Public Functions
  function purchase(uint256 _salt) external payable returns (bool) {
    // Payment
    uint256 total = inventory.length;
    require(minted < total, "MegaSales: sold out");
    require(msg.value >= price, "MegaSales: insufficient msg.value");
    payable(owner).transfer(msg.value);

    // Random Draw
    uint256 index = random(_salt, total - minted);
    uint256 tokenId = inventory[index];

    // Deliver NFT
    IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
    emit Purchase(tokenId, msg.sender);

    // Update Inventory
    inventory[index] = inventory[total - minted - 1];
    minted++;

    return true;
  }

  // Private Functions
  function random(uint256 _salt, uint256 _modulo) public view returns (uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(_salt, block.timestamp)));
    return seed % _modulo;
  }

  // Admin Functions
  function setNft(address _nft) external onlyOwner returns (bool) {
    require(!initialized, "MegaSales: contract already initialized");
    nft = _nft;
    return true;
  }

  function initInventory(uint256 _count) external onlyOwner returns (bool) {
    require(!initialized, "MegaSales: contract already initialized");
    for(uint256 i = 1; i <= _count; i++) {
      inventory.push(i);
    }
    initialized = true;
    return true;
  }

  function setPrice(uint256 _price) external onlyOwner returns (bool) {
    price = _price;
    return true;
  }
}