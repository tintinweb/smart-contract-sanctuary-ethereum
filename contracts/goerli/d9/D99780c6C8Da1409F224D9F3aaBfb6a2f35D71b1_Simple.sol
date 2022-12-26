// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Simple {
    uint public count;  
    function getA() public view returns(uint) {
        return count;
    }
    function setA(uint _a) public {
        count = _a;
    }
    function add(uint _a, uint _b) public pure returns(uint) {
        return _a + _b;
    }
}