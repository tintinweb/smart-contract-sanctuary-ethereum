// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract BoxV4 {
    uint public val;

    function inc() external {
        val += 1;
    }

    function dec() external {
        val -= 1;
    }
}