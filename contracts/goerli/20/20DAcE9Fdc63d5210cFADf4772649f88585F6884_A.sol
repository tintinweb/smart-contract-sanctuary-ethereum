// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract A {
    uint[] arr;

    function getArrLength() public view returns(uint) {
        return arr.length;
    }

    function setArr(uint _a) public {
        arr.push(_a);
    }

    function getBigger(uint _a, uint _b) public pure returns(uint) {
        if(_a >= _b){
            return _a;
        } else {
            return _b;
        }
    }
}