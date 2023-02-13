/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Token {
  string public name = "Aarav Krishna Token";
  string public symbol = "AKT";
  uint public totalSupply = 1000000;
  mapping(address => uint) balances;

  constructor() {
    balances[msg.sender] = totalSupply;
  }

  function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount, "Not enough tokens");
    balances[msg.sender] -= amount;
    balances[to] += amount;
  }

  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }
}