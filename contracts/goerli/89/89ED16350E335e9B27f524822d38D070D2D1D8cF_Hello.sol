// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Hello {
  string public name;
  address public owner;
  uint256 public balance;

  constructor(string memory _name) {
    name = _name;
    owner = msg.sender;
    balance = 100;
  }

  function increaseBalance(uint256 _amount) public {
    require(msg.sender == owner, "No no no");
    balance = balance + _amount;
  }

  function decreaseBalance(uint256 _amount) public {
    require(msg.sender == owner, "No no no");
    require(balance - _amount >= 0, "Can't subtract the balance below zero");
    balance = balance - _amount;
  }
}