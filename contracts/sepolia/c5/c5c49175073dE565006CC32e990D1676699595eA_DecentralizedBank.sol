/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedBank {
    mapping(address => uint256) accountBalances;

    function getBalance() public view returns (uint256) {
        return accountBalances[msg.sender];
    }

    function deposit() public payable {
        accountBalances[msg.sender] += msg.value;
    }

    function withdraw() public {
        payable(msg.sender).transfer(accountBalances[msg.sender]);
        accountBalances[msg.sender] = 0;
    }
}