// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
//pragma experimental SMTChecker;

contract OF{
    uint public value=15;  // f in hexa in the stack
    function increment() external{
        value=value+5;    // 5 in hexa in the stack
    }
}