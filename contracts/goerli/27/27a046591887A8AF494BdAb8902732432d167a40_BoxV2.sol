// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract BoxV2 {
    uint public val;

    function increment() external {
        ++val;
    }
}