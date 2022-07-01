//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GreeterTqq {
    string private greeting;
    uint public bigNum;
    event SetGreeting(string _greeting);
    event GetNewNum(uint num);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;

        emit SetGreeting(_greeting);
    }

    function getNewNum(uint num) public {
        bigNum =  num * 10;
        emit GetNewNum(num);
    }
}