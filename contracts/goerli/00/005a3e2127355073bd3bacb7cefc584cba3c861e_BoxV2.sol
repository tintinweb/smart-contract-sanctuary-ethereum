/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// contracts/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
 
contract BoxV2 {
    uint256 private value;
    //uint256 public valueT1 = 1;
    //bool public stateT1 = false;
    bool public stateT1;
    uint256 public valueT1;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        stateT1 = false;
        valueT1 = 10;
        emit ValueChanged(newValue);
    }
    
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
    
    function burn(uint256) external {
        value = 0;
        emit ValueChanged(0);
    }

    // Increments the stored value by 1
    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
    
    // Increments the stored value by 1
    /**function collate_propagate_storage(bytes16 y) public {
        value = value + 1;
        emit ValueChanged(value);
    }*/
}