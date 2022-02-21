// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Box {
    uint256 private value;
    uint256 private times;
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        times = 503;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    function howmuch2() public view returns (uint256) {
        return times;
    }
}