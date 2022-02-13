/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: BoxV3.sol

contract BoxV3 {
    uint256 private value;
    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function multiply(uint256 multiplier) public {
        value = value * multiplier;
        emit ValueChanged(value);
    }
}