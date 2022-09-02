/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract MyToken{
address public owner;
mapping(address => uint) public balances;
modifier onlyOwner() {
require(owner == msg.sender, "Caller is not owner");
_;
}
constructor() {
owner = msg.sender;
}
function mint(address recipient, uint amount) onlyOwner public {
balances[recipient] += amount;
}
function transfer(address to, uint amount) public {
require(amount <= balances[msg.sender], "Insufficient amount");
balances[msg.sender] -= amount;
balances[to] += amount;
}
}