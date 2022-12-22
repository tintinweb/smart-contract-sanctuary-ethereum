//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract A {
    uint num;
    
    function getNum() public view returns(uint) {
        return num;
    }

    function setNum(uint _a) public {
        num = _a;
    }
}