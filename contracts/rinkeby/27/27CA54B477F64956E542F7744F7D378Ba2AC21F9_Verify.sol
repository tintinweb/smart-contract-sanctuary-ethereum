//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {
        greeting = "It's a good day";
    }

    function hello(bool sayHello) public view returns (string memory) {
        if(sayHello) {
            return "hello";
        }
        return greeting;
    }
}