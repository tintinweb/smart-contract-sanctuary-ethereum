// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box4 {
    uint256 private value;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store4(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve4() public view returns (uint256) {
        return value;
    }

    // // Reads the last stored value
    // function retrieve4() public view returns (uint256) {
    //     return 5;
    // }
}