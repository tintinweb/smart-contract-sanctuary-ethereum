/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Yzy {
  mapping (address => uint) balances;

  constructor() {
    balances[tx.origin] = 100;
  }

  function addUser(address user) public returns(bool) {
    //require(balances[user] == 0, "user already exists!");
    balances[user] = 100;

    return true;
  }

  function depositMoney(address user, uint amount) public returns(bool) {
    require(balances[user] > 0, "failed to find user");

    balances[user] += amount;
    return true;
  } 

  function sendMoney(address receiver, uint amount) public returns(bool) {
      if (balances[msg.sender] < amount) {
          return false;
      }

      balances[msg.sender] -= amount;
      balances[receiver] += amount;
      return true;
  }

  function getBalance(address addr) public view returns(uint) {
    return balances[addr];
  }
}