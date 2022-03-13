/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld{
    string public Greetings;

    constructor (){
        Greetings = "Hello World";
    }

    function add(uint x, uint y) external pure returns (uint){
        return x + y;
    }

    function sub(uint x, uint y) external pure returns (uint) {
        return x - y;
    }
}