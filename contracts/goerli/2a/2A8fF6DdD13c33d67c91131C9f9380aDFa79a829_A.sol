//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;
contract A {
    uint a;
    function setA(uint _a) public {
        a = _a;
    } 
    function getA(uint _a) public pure returns(uint){
        return _a;
    }
}