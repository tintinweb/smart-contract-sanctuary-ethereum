// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV2 {
    uint256 public value;

    function inc() public {
        value += 1;
    }
}