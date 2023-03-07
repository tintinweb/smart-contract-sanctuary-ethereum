// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Box {
    uint256 private value;

    //Emitted when the store value changes
    event ValueChange(uint256 newValue);

    //Store a new value in the contract
    function storeValue(uint256 newValue) public {
        value = newValue;
        emit ValueChange(newValue);
    }

    //Read the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}