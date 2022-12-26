//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test {
    uint[] uintArray;

    function getArrayLength() public view returns(uint) {
        return uintArray.length;
    }

    function setArray(uint _number) public {
        uintArray.push(_number);
    }

    function getBiggerNumber(uint _numberA, uint _numberB) public pure returns(uint) {
        if(_numberA > _numberB){
            return _numberA;
        }else{
            return _numberB;
        }
    }

}