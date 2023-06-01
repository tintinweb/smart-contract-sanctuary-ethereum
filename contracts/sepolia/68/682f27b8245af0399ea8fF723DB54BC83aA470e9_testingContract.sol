// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract testingContract {
    uint constant  balance = 12; 
    
    function getBalance() external pure returns(uint){
        return balance;
    }
}