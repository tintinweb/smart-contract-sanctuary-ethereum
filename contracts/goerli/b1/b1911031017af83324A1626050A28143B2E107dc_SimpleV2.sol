// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleV2 {
    uint256 value;

    event ValueChanged(uint256 value);

    function changeValue(uint256 newValue) external returns (uint256) {
        value = newValue;
        emit ValueChanged(value);
        return value;
    }

    function getValue() external view returns (uint256) {
        return value;
    }

    function addOne() external returns (uint256) {
        value = value + 1;
        emit ValueChanged(value);
        return value;
    }
}