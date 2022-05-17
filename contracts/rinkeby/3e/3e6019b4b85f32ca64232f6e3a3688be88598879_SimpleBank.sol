/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint )  accountBook;

    function withdraw(uint amount) external payable {
        require(accountBook[msg.sender]>=amount,"Don't have enough money");
        
        accountBook[msg.sender] -= amount;
        bool sent = payable(msg.sender).send(amount);
        require(sent,"sent fail");

        // Implement withdraw function…… 
    }

    function deposit() external payable {
        accountBook[msg.sender] += msg.value;

        // Implement deposit function……
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
        
        // Implement getBalance function……
    }
}