//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint[] aArray;

    function getLength() public view returns(uint) {
        return aArray.length;
    }

    function pushArray(uint _num) public {
        aArray.push(_num);
    }

    function lgNumberComparsion(uint _num1, uint _num2) public pure returns(uint) {
        return (_num1 >= _num2) ? _num1 : _num2;
    }
}