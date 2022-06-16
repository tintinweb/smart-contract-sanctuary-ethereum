/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hello {

    string public hello = "Hello World!";

    // Patipan Bio
    string public firstName = "Patipan";
    string public lastName = "Buranangura";

    uint256 public age = 23;
    uint256 public money = 100;

    // function
    function deposit(uint256 _amount) public {
        for(uint256 i=0; i<10; i++){
            money += _amount;
        }
    }
}