// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Deployed at

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
    require(msg.sender == owner, "Can't change the balance if not the owner");
    balance = balance + _amount;
  }

  function decreaseBalance(uint256 _amount) public {
    require(msg.sender == owner, "Can't change the balance if not the owner");
    require(balance - _amount >= 0, "Can't make the balance negatie");
    balance = balance - _amount;
  }
}