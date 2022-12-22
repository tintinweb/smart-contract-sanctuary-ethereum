// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Simple{
    uint a;

    function getA() public view returns(uint){
        return a;
    }

    function setA(uint _a) public{
        a = _a;
    }
}