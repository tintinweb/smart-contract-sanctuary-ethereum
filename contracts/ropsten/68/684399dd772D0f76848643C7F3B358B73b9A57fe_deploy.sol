/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract deploy{
    address owner;
    uint256 balance;
    
    constructor(){
        owner = msg.sender;
    }

    receive() payable external{
        balance = balance + msg.value;
    }

    function withdraw(uint amount, address payable destAddr) public {
        require (msg.sender == owner);
        destAddr.transfer(amount);
        balance = balance - amount;
    }

}