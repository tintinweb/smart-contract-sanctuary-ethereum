/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyBank {
    mapping (address => uint256) public balance;

    address[] public accounts;

    function deposit() public payable {
        if (balance[msg.sender] ==0) {
            accounts.push(msg.sender);
            }
            balance[msg.sender] +=msg.value;
    }
}