//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HelloWorld {
    string private greeting;
    event newGreeting(string _greeting);

    constructor() {
        greeting = "Hello, World";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit newGreeting(_greeting);
    }
}