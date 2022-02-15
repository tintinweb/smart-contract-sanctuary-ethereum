/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;
    // The contract doesn't have a constructor because we want our state do be stored
    // in the proxy, and the constructors save the state in the contract that's constructed

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}