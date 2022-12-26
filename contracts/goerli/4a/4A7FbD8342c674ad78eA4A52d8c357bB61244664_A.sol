// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    uint public a;
    uint[] arr;

    function setArr(uint _a) public {
        _a = a;
        arr.push(_a);
    }

    function getArr() public view returns(uint) {
        return arr.length;
    }

    function compare(uint b, uint c) public pure returns(uint) {
        if (b >= c) {
            return b;
        } else {
            return c;
        }
    }
}