// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV3 {
    uint256 private value;

    event ValueChanged(uint256 _newValue);

    function store(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(_newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function decrement() public {
        value = value - 1;
        emit ValueChanged(value);
    }
}