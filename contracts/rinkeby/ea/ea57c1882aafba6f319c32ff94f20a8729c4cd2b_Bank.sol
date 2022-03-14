/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bank {
    // Declare accounts parameter
    mapping(address => uint256) private accounts;
    // Get balance
    function balance() public view returns (uint256) {
        return accounts[msg.sender];
    }

    // Deposit function
    function deposit() public payable{
        require(msg.value > 0, "Amount must more than 0.");
        accounts[msg.sender] += msg.value;
    }

    // Withdraw function
    function withdraw(uint256 money) public {
        require(money <= accounts[msg.sender], "Balance is not enough.");
        payable(msg.sender).transfer(money);
        accounts[msg.sender] -= money;

    }
}