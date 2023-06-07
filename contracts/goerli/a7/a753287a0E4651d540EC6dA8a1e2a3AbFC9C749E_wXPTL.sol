/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract wXPTL {
  string public name = "Faux wXPTL";
  string public symbol = "fwXPTL";
  uint256 public totalSupply = 500000;

  mapping(address => uint256) public balances;

  constructor() {
    balances[msg.sender] = totalSupply;
  }

  function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");

    balances[msg.sender] -= amount;
    balances[to] += amount;
  }
}