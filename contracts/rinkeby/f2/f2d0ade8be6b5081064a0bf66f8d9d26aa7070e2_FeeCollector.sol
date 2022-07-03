/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector { // 
    address public owner;
    uint256 public balance;
     uint256 public value;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }

    function mint(uint256 _val) public payable {
        require(msg.value > 0.01 ether);
        value = _val;
        balance += msg.value;
    }
    

    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
}