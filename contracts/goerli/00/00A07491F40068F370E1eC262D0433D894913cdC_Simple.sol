//contracts/A.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint[] a;
    
    function getLength() public view returns(uint) {
        return a.length;
    }

    function push(uint _a) public {
        a.push(_a);
    }
    function getBiggerNumber(uint _numA, uint _numB) public pure returns(uint){
        return _numA >= _numB ? _numA : _numB;
    }
}