/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector { //0x39999491E1d05c6eAa8F9F1bB995D946a60ec827
    address public owner;
    uint256 public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance += msg.value;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        destAddr.transfer(amount);
        balance -= amount;
    }

    
}