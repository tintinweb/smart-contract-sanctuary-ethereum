/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld{
    string public hello= "Hello World";
    
    //Tanakrit Bio
    string public fullname="Tanakrit Chanplakorn";
    uint256 public age = 20;
    uint256 public money = 1500;

    //function
    function deposit(uint256 _amount) public {
        money+=_amount;
    }
}