/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    address child;
    address owner;
    uint maxWithdrawAmount;
    
    constructor(address _child, uint _maxWithdrawAmount) {
        owner = msg.sender;
        child = _child;
        maxWithdrawAmount = _maxWithdrawAmount;
    }
    
    modifier isChild() {
        require(msg.sender == child);
        _;
    }
    
    function deposit() payable public {
    }
    
    function withdraw(uint amount) public isChild() {
        require(amount <= address(this).balance, "Amount greater than balance");
        require(amount <= maxWithdrawAmount, "Amount greater that maximum allowed limit");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}