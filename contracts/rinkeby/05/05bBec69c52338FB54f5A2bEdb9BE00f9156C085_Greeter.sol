//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    bool private start;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function now() public {
        start = !start;
    }

    function setGreeting(string memory _greeting) public {
        require(start, "not yet");
        greeting = _greeting;
    }
}