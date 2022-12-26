//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A {
    uint[] public count;
    
    function getA() public view returns(uint) {
        return count.length;
    }

    function setA(uint _a) public {
        count.push(_a);
    }

    function compare(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b){
            return _a;
        } else {
            return _b;
        }
        }
}