// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract T{
    uint [] testArray;

    function getLength() public view returns(uint) {
        return testArray.length;

    }

    function changeT(uint _n) public {
        testArray.push(_n);
    }

    function compareT(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b) {
            return _a;
        }else {
            return _b;
        }
    }
}