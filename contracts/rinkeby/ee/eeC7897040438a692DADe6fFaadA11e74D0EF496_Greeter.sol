//SPDX-License-Identifier: Unlicense
// test deploy 6
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    string private _test;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }


}