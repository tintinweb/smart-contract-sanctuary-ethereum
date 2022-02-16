/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BHeroDetails {
  uint256 public constant ALL_RARITY = 0;

  struct Details {
    uint256 id;
    uint256 index;
    uint256 rarity;
    uint256 level;
    uint256 color;
    uint256 strength;
    uint256 health;
    uint256 defence;
  }

  function tesst(uint256 a, uint256 b) external pure returns(uint256) {
    uint256 fee = a * b / 10000;
    return fee;
  }

  function encode(uint256 id, uint256 index, uint256 rarity, uint256 level, uint256 color, uint256 strength, uint256 health, uint256 defence) external pure returns (uint256) {
    uint256 value;
    value |= id;
    value |= index << 30;
    value |= rarity << 40;
    value |= level << 50;
    value |= color << 60;
    value |= strength << 70;
    value |= health << 80;
    value |= defence << 90;

    return value;
  }

  function decode(uint256 details) external pure returns (Details memory result) {
    result.id = details & ((1 << 30) - 1);
    result.index = (details >> 30) & ((1 << 10) - 1);
    result.rarity = (details >> 40) & ((1 << 10) - 1);
    result.level = (details >> 50) & ((1 << 10) - 1);
    result.color = (details >> 60) & ((1 << 10) - 1);
    result.strength = (details >> 70) & ((1 << 10) - 1);
    result.health = (details >> 80) & ((1 << 10) - 1);
    result.defence = (details >> 90) & ((1 << 10) - 1);
  }
}

contract tess {
  mapping (address => uint256) public deposits;
  uint256 public cost = 0.1 ether;
  function testpay() public payable {
    require(msg.value >= cost, "Insufficient funds!");
    deposits[msg.sender] += msg.value;  
  }
  function balanceAddress() public view returns(uint256){
    uint256 balance = address(this).balance;
    return balance; 
  }
  receive() external payable {}

  function withdrawBalance() external {
      uint256 balance = address(this).balance;
      require(balance > 0, "Balance invalid");
      (bool result,) = msg.sender.call{value: balance}("");
      require(result, "Withdraw Balance Error");
  }
}