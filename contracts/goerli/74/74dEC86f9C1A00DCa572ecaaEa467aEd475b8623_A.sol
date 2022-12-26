//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract A {
    uint[] AA;

    function getLength() public view returns(uint){
        return AA.length;
    }

    function renew(uint _a, uint _b) public {
        AA[_a] = _b;
    }

    function biggerNumber(uint _a, uint _b) public pure returns(uint) {
        if(_a > _b) {
            return _a;
        } else{
            return _b;
        }
    }
}