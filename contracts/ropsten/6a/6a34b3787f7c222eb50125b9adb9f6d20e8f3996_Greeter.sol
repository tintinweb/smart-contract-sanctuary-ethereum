/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: UNLICENSED


pragma solidity >0.5.0;


contract Greeter {
    string public greeting;

    constructor() {
        greeting = 'Hello world';
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet() view public returns (string memory) {
        return greeting;
    }
}