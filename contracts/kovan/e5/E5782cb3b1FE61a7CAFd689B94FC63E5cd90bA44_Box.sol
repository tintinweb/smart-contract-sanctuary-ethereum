// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private value;

    event ValueChanged(uint256 neewValue);

    function store(uint256 neewValue) public {
        value = neewValue;
        emit ValueChanged(neewValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}