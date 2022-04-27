// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;

contract HelloWorld3{
    string greeting;

    constructor(string memory _greeting){
        greeting = _greeting;
    }

    function getGreeting() public view returns (string memory){
        return greeting;
    }

    function setGreet(string memory _greeting) public {
        greeting = _greeting;
    }




}