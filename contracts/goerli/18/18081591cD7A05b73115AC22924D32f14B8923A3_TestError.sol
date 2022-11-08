// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestError {
    error Hello();
    uint public a;
    function set(uint _a) public{
        if(_a < 5) {
            revert Hello();
        }
        a = _a;
    }
}