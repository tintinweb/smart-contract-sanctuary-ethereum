/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

contract Bank {

  int bal = 1;


  function getBalance() view public returns(int){
      return bal;
  }

  function withdraw(int amt) public{
      bal = bal - amt;
  }

  function deposit(int amt) public{
      bal = bal + amt;
  }
}