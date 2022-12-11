/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MyBank {
    mapping (address => uint256) public balances;

    address[] public accounts;

    function deposit() public payable {
        if (balances[msg.sender] == 0) {
            accounts.push(msg.sender);
        }
        balances[msg.sender] += msg.value;
    }
}