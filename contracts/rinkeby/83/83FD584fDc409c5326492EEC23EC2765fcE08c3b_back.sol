/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: bank.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract back {
    mapping(address => uint256) balance;


    function deposit () public payable {
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public payable {
        require (_amount <= balance[msg.sender], "Not enough money");

        payable(msg.sender).transfer(_amount);
        balance[msg.sender] -= _amount;
    }

    function checkBalanceUsers() public view returns (uint256) {
        return balance[msg.sender];
    }
}