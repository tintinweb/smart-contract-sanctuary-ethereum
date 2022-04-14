/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// File: BoxV3.sol

contract BoxV3 {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit ValueChanged(newValue);
    }

    function retrieve() public view returns(uint256){
        return value;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }

    function increment_multiple() public {
        value = value * 2;
        emit ValueChanged(value);
    }
}