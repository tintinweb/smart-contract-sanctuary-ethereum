// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestError {
    error Hello();
    error Hi();
    uint public a;
    uint public c;
    function set(uint _a) public{
        set2(_a);
        uint b = _a * 5;
        uint _c = b - 10;
        if(c<40) {
            revert Hi();
        }
        a = _a;
        c = _c;
    }

    function set2(uint _a) public pure {
        if(_a < 5) {
            revert Hello();
        }
    }
}