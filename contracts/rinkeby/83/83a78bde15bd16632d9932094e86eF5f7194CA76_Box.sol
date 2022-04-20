/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: Box.sol

contract Box {
    uint256 private value;
    event valueChanged(uint256 newValue);

    function store(uint256 newValue) public {
        value = newValue;
        emit valueChanged(newValue);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}