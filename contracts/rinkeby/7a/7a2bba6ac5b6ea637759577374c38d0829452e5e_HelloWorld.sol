/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract HelloWorld {
    string public greeting;

    constructor() {
        greeting = "Hello World";
    }

    function setGreeting(string memory _newGreeting) public {
        greeting = _newGreeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}