//SPDX-License-Identifier: Unlicense
// test deploy 6
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    string private arg2;

    constructor(string memory _greeting, string memory _arg2) {
        greeting = _greeting;
        arg2 = _arg2;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }


}