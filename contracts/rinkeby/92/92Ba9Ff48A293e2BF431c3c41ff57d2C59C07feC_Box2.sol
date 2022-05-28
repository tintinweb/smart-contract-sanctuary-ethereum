/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
 
contract Box2 {
    uint256 private value;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = 2*newValue;
        emit ValueChanged(2*newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }
}