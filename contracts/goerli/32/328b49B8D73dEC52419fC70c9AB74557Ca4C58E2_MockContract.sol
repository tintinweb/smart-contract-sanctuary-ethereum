// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract MockContract{
    int256 public counter;

    function increment() public {
        counter++;
    }

    function decrement() public {
        counter--;
    }
    
    function reset() public {
        counter = 0;
    }
}