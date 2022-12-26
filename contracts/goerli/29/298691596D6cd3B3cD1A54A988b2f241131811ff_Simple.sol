//contracts/A.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Simple {
    uint a;
    
    function getA() public view returns(uint) {
        return a;
    }

    function setA(uint _a) public {
        a = _a;
    }

    function add(uint _a1, uint _b1) public pure returns(uint) {
        return _a1 + _b1;
    }
}