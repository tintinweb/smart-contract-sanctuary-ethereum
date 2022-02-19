// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract bankAccount{

    //owner = msg.sender;

    mapping(address => uint) public ownerBalance;
    
    function deposit(uint depAmount) public payable {
        require(msg.value == depAmount);
        ownerBalance[msg.sender] += depAmount;
    }
    
    function withdraw(uint wdAmount) private {
        require(wdAmount <= ownerBalance[msg.sender]);
        ownerBalance[msg.sender] -= wdAmount;
        payable(msg.sender).transfer(wdAmount);
    }
}