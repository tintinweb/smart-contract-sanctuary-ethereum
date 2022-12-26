// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Simple {
    uint a;
    function getA() public view returns(uint){
        return a;
    }
    function setA(uint _a) public{
        a = _a;
    }
    function add(uint _a, uint _b) public view returns(uint){
        return _a+_b;
    }
}