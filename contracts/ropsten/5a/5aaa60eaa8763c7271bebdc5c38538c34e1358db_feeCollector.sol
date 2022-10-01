/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract feeCollector {

address public owner;
uint256 public balance;

constructor() {
owner = msg.sender;

}

receive() payable external {

balance += msg.value; 

}

}