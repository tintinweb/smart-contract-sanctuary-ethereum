/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Box {
    uint256 private value;

    bool public stateT1;
    uint256 public valueT1;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);

        stateT1 = true;
        valueT1 = 1;
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    // Reset the value
    function burn(uint256) external {
        value = 0;
    }
}