// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;

    // Emitted when stored value changes
    event ValueChanged(uint256 newValue);

    // Stores the new value in the contract
    function store(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(_newValue);
    }

    // Reads the last stored value
    function retreive() public view returns (uint256) {
        return value;
    }

    // Increment the value by 1
    function increment() public {
        value += 1;
        emit ValueChanged(value);
    }
}