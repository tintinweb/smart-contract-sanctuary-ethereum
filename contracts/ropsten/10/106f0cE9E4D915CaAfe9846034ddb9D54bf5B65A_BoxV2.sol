//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BoxV2 {
    uint public val;
    uint public balance;

    function inc() external {
        val += 1;
    }
}