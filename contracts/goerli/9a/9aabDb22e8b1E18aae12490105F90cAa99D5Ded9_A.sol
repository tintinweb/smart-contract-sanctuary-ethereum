// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract A {

    uint[] numbers;

    function getLength() public view returns(uint){
        return numbers.length;
    }

    function pushNumber(uint _a) public { 
        numbers.push(_a);
    }

    function compare(uint _a, uint _b) public pure returns(uint){
        return (_a >= _b ? _a : _b);
    }
}