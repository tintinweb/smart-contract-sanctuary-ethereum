// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyToken  {

    uint private num;

    constructor(uint _num){
        num = _num;
    }

    function setNum(uint _num) public {
        num = _num;
    }

    function getNum() public view returns(uint){
        return num;
    }
}