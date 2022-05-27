// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    uint constant _perc = 100;

    function extractPercentage(uint value, uint perc) public pure returns (uint) {
        return value - (value * perc / _perc);
    }

    function extractPart(uint part, uint parts, uint amount) public pure returns(uint) {
        return (parts > 0) ? amount * part / parts : 0;
    }
}