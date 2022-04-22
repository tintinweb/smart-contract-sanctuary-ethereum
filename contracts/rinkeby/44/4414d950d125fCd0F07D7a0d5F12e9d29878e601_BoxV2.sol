// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

contract BoxV2 {
    uint256 private value;

    event ValueChanged(uint256 indexed newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value++;
        emit ValueChanged(value);
    }
}