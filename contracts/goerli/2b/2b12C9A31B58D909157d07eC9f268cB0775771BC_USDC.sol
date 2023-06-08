/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDC {
string public name = "Faux USDC";
string public symbol = "fUSDC";
uint256 public totalSupply;

mapping(address => uint256) public balances;

event Transfer(address indexed from, address indexed to, uint256 amount);

constructor() {
balances[msg.sender] = totalSupply;
}

function transfer(address to, uint256 amount) external {
require(balances[msg.sender] >= amount, "Solde insuffisant");

    balances[msg.sender] -= amount;
    balances[to] += amount;

    emit Transfer(msg.sender, to, amount);
  }

function mint(uint256 amount) external {
require(msg.sender == 0xF90aCf91BdAB539aAC3093E5C5b207b562354401, "Autorisation refusee");

    balances[msg.sender] += amount;
    totalSupply += amount;

    emit Transfer(address(0), msg.sender, amount);
  }
}