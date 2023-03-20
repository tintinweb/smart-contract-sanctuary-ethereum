/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: GPL - 3.0

pragma solidity >= 0.8.2 <0.9.0;

contract Bank {

    mapping(address => uint256) public depositTime;
    mapping(address => uint256) public balance;

    function deposit() public payable {
        depositTime[msg.sender] = block.timestamp;
        balance[msg.sender] = balance[msg.sender] + msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount <= balance[msg.sender], "Not enough money!");
        require(block.timestamp > depositTime[msg.sender] + 2 minutes, "You have to wait");
        payable(msg.sender).transfer(amount);
    }

    function checkBalance(address target) public view returns (uint256){
        return balance[target];
    }

}