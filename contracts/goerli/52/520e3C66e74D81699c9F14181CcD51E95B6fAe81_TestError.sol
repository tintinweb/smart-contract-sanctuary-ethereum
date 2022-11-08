// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestError {
    error Hello();
    error Hi();
    uint public a;
    uint public c = 5;
    function set(uint _a) public{
        if(_a * c < 25){
            revert Hello();
        }
        a = _a;
    }
}