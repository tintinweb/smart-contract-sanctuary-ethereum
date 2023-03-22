// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    event Increment(uint256 number);
    event SetNumber(uint256 number);

    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit SetNumber(number);
    }

    function increment() public {
        number++;
        emit Increment(number);
    }
}