// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
contract Box {
    uint256 private value;
    address private someone;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function storeSomeone(address newSomeone) public {
        someone = newSomeone;
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}