// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleContract {
    address public owner;
    uint256 public value;

    constructor() {
        owner = msg.sender;
    }

    function addToValue(uint256 amount) public {
        value += amount;
    }

    function subFromValue(uint256 amount) public {
        value -= amount;
    }
}