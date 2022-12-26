//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint[] testArr;
    
    function getArrLen() public view returns(uint) {
        return testArr.length;
    }

    function pushArr(uint _a) public {
        testArr.push(_a);
    }

    function compareAB(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b) return _a;
        else return _b;
    }
}