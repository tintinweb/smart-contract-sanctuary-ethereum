// SPDX-License-Identifier: MIT 
pragma solidity ^0.6.12;

contract TestOverAndUnderflow {
    uint public x;
    int8 public y;
    uint public z;

    constructor() public {
        x = type(uint).max;
        y = type(int8).max;
        // https://ethereum.stackexchange.com/questions/80081/what-is-the-purpose-of-uint256-1
        z = uint(-1);
    }

    function overflow() public{
        x += 1;
        y += 1;
    }

    function resetUnderflow() public {
        x = 0;
        y = type(int8).min;
    }

    function underflow() public {
        x -= 1;
        y -= 1;
    }
}