// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Number {

    uint public number;

    constructor(uint _number) {
        number = _number;
    }

    function updateNumber(uint to) public {
        number = to;
    }

    function incrementNumber() external {
        number += 3;
    }
}