// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// since these are proxies, we do NOT have constructors
// have "initializer" function instead

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