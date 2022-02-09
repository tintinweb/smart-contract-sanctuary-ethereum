// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 public x;
    bool private initialized;

    function inc() public {
        x++;
    }
}