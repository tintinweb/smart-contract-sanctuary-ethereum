// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Simple {
    uint public count;  
    function getA() public view returns(uint) {
        return count;
    }

    function setA(uint _a) public {
        count = _a;
    }
}