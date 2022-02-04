// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Box {
    uint256 private value;

    //Emit event when the stored value changes
    event ValueChanged(uint256 newValue);

    //Store a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    //Read the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}