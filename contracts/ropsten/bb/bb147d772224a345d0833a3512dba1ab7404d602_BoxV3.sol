// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV3 {
    uint256 public x;
    bool private initialized;

    function inc() public {
        x++;
    }

    function dec() public {
        x--;
    }
}