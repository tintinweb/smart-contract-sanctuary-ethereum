// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    // This function can only be called in BoxV2.sol, not Box.sol
    function increment() public {
        ++value;
        emit ValueChanged(value);
    }
}