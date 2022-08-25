// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Oracle{
  address owner;
  uint256 price;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require( owner == msg.sender,  'No sufficient right');
      _;
  }

  function setOwner() onlyOwner external {
     owner = msg.sender;
  }

   function setPrice(uint256 price_) onlyOwner external {
     price = price_;
  }

  function getPrice() external view returns (uint256) {
    return price;
  }
}