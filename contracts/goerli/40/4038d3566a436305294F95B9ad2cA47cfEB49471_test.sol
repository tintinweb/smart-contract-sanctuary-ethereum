// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract test {
    uint[] array;

    function getArrLen() public view returns(uint) {
        return array.length;
    }

    function pushArr(uint _n) public {
        array.push(_n);
    }

    function isBigger(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b) {
            return _a;
        } else {
            return _b;
        }
    }
}