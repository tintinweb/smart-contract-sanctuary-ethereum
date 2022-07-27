// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    address public owner;
    uint public num;

    constructor(){
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setNum(uint _num) public restricted {
        num = _num;
    }
}