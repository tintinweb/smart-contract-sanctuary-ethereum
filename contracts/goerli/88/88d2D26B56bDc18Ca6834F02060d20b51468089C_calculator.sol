// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract calculator {
    uint result = 0;

    function add(uint a, uint b) public {
        result = a + b;
    }

    function sub(uint a, uint b) public {
        result = a - b;
    }

    function mul(uint a, uint b) public {
        result = a * b;
    }

    function display() public view returns (uint) {
        return result;
    }
}