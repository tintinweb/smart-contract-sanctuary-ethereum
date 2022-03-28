// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Balance {

    uint private varA;

    constructor() {
        varA = 100;
    }

    function setVarA(uint minusA) public {
        varA = varA - minusA;
    }

    function getVarA() public view returns (uint) {
        return varA;
    }
}