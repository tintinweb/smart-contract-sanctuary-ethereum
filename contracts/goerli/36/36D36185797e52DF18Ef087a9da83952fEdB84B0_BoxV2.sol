// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract BoxV2 {
    uint256 private val;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
  
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        val = newValue;
        emit ValueChanged(newValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return val;
    }
    
    // Increments the stored value by 1
    function increment() public {
        val = val + 1;
        emit ValueChanged(val);
    }
}