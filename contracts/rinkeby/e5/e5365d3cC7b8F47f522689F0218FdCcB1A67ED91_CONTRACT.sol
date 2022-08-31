// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract CONTRACT {
    string public variable1;
    string public variable2;

    constructor(string memory variable1_, string memory variable2_) {
        variable1 = variable1_;
        variable2 = variable2_;
    }

    function sampleSum(uint number1, uint number2) external pure returns (uint) {
        return number1 + number2;
    }
}