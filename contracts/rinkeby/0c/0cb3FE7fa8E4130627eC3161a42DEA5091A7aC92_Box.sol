// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract to store and retrieve some type of value
contract Box {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}