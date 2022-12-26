//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A {
    uint[] array;

    function getArrayLength() public view returns(uint) {
        return array.length;
    }
    
    function pushNumber(uint a) public{
        array.push(a);
    }

    function compar(uint a, uint b) public view returns(uint) {
        if(a > b) {
            return a;
        } else {
            return b;
        }

    }
}