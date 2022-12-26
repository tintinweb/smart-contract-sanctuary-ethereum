//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint[] array;

    function getArray() public view returns(uint) {
        return array.length;
    }

    function setArray(uint _a) public {
        array.push(_a);
    }
    function bigSort(uint _a, uint _b) public pure returns(uint) {
        if(_a>=_b) {
            return _a;
        } else {
            return _b; 
        }
    }
}