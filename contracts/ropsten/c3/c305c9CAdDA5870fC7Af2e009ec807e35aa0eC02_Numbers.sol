//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Numbers {

    uint public myNumber;
    uint public cannotChange;

    constructor(uint _number) {
        myNumber = _number;
        cannotChange = 69;
    }

    function setMyNumber(uint _number) public {
        myNumber = _number;
    }
}