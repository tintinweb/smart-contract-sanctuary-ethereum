// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract C {

    uint256 public constant num = 11;
    uint256 public incremented;

    function foo() external {
        for (uint256 i; i < num;) {
            incremented++;
            unchecked { i++; }
        }
    }
}