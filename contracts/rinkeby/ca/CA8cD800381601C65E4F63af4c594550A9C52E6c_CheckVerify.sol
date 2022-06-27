// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract CheckVerify {
    uint256 immutable x;

    constructor(uint256 _x) {
        x = _x;
    }

    function myFunc() external view returns(uint256) {
        return x;
    }
}