// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Counter {
    uint256 public number;
    string public author;

    constructor(uint256 _number, string memory _author) {
        number = _number;
        author = _author;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
 
}