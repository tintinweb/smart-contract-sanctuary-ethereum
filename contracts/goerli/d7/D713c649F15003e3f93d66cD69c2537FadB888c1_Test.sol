// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Test {
    uint256 public immutable a;

    constructor(uint256 _a) {
        a = _a;
    }
}