/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: Box.sol

contract Box {
    uint256 private value;

    event valueChange(uint256 new_value);

    function store(uint256 new_value) public {
        value = new_value;
        emit valueChange(value);
    }

    function retrieve() public view returns (uint256) {
        return value;
    }
}