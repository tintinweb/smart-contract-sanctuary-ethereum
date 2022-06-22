/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string public hello = "Hello World";
    uint256 public money = 100;

    //function
    function deposit(uint256 _amount) public {
        money += _amount;
    }
}