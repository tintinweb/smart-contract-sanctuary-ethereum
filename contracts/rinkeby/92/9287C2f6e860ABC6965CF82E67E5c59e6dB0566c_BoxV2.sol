// contracts/BoxV2.sol
// SPDX-License_Identifier: MIT
pragma solidity ^0.8.0;
 
contract BoxV2 {
    uint256 private value;
    event ValueChanged (uint256 newValue);
 
     // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}