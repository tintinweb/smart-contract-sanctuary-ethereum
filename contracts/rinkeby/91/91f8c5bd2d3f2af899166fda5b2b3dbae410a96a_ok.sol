/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// uint 整数 
contract ok{


    uint public num1; 
    uint private num2;

function set_value() public{

    num1 = 1;
    num2 = 2;


}

function add() public returns(uint) {

    return(num1 + num2);


}


}