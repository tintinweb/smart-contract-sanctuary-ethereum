// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;
    event ValueChange(uint256 value);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChange(value);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    // V2
    function increment() public {
        value++;
        emit ValueChange(value);
    }
}