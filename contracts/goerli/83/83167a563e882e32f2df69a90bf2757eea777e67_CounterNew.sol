// SPDX-License-Identifier: No Liscense
pragma solidity >=0.8.0;

contract CounterNew {
    uint256 public counter;
    address public owner;
    address public implementation;

    function increment() public {
        counter++;
    }

    function setCounter(uint256 a) public {
        counter = a;
    }
}