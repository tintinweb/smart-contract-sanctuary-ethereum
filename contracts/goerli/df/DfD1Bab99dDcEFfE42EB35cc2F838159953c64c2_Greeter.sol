// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

contract Greeter {
    string private greeting;

    constructor(string memory greeting_) {
        greeting = greeting_;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory newGreeting) public {
        greeting = newGreeting;
    }
}