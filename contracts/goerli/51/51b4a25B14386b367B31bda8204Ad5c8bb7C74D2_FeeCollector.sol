/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// File: FeeCollector.sol

pragma solidity  ^0.8.17;
//SPDX-License-Identifier: MIT
contract FeeCollector {
  
  address public owner;
  uint256 public balance;

  constructor() {
     owner=msg.sender;
  }  

  receive() payable external {
     balance = balance + msg.value;
  }
  
  function withdraw (uint amount, address payable destAddr) public {
     require(msg.sender == owner,"Only the owner can withrow asset from the contract!");
     require(amount <= balance, "Insufficient funds!");
     destAddr.transfer (amount);
     balance = balance - amount;
  }
}