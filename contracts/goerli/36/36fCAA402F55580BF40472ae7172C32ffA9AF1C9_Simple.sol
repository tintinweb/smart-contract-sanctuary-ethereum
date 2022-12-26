//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.9.0;

contract Simple {
    uint[] public valueArray;

    function getArrayLength() public view returns(uint) {
        return valueArray.length;
    }

    function setArrayLength(uint _value) public {
        valueArray.push(_value);
    }

    function compare(uint a, uint b) public view returns (uint) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    } 
}