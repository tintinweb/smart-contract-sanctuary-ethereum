/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract PiggyBank {

    uint256 balance;
    
    function getBalance() public view returns(uint256) {
        return balance;
    }

    function deposit(uint256 amount) public {
        balance += amount; 
    }
}