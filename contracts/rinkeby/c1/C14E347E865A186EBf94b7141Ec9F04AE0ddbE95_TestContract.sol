// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

contract TestContract {
    uint256 public a;
    uint256 public b;

    uint256 public sum;

    constructor(uint256 _a, uint256 _b) {
        a = _a;
        b = _b;

        sum = _a + _b;
    }

    function calcSum(uint256 _a, uint256 _b) external pure returns (uint256) {
        return _a + _b;
    }

    function writeSum(uint256 _a, uint256 _b) external {
        a = _a;
        b = _b;

        sum = _a + _b;
    }
}