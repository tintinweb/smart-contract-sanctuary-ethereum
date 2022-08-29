/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector { // 
    address public owner;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }
    
    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }
    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only Billion can withdraw");
        require(amount <= balance, "You're broke, anon");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
}