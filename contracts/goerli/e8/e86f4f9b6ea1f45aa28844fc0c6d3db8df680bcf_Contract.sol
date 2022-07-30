// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    uint256 private _value;

    function set(uint256 value) external {
        _value = value;
    }

    function get() external view returns (uint256) {
        return _value;
    }
}