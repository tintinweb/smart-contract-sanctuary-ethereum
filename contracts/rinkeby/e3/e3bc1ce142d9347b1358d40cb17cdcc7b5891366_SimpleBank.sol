/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private Balance;

    function withdraw(uint amount) external payable {
        require(Balance[msg.sender] >= amount, "Insufficient balance.");
        (bool sent, )= payable(msg.sender).call{value: amount}("");
        require(sent, "Send failed.");
        Balance[msg.sender]-=amount;
    }

    function deposit() external payable {
        Balance[msg.sender]+=msg.value;
    }

    function getBalance() public view returns (uint) {
        return Balance[msg.sender];
    }
}