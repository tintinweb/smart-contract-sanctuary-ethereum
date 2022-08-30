/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Greeter{
    string public greeting;

    constructor(){
        greeting = "Hello";
    }

    function setGreeting(string memory _greeting) public{
        greeting = _greeting;
    }

    function getGreeting() view public returns (string memory){
        return greeting;
    }
}