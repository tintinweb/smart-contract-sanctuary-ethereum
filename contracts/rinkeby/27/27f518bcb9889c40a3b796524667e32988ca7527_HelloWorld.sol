/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // use compiler version 0.8.0

contract HelloWorld { //contract name
    // delare variable
    string public hello = "Hello World";

    string public name = "Hello";

    uint256 public age = 24;
    
    uint256 public money = 0;

    // function
    function deposit(uint _amount) public {
        // money = money + 1000;
        money += _amount;
    }
}