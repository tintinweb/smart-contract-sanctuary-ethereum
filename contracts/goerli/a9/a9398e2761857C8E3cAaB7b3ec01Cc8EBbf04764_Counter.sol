/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
    uint256 public sum;

    function add(uint256 x) external returns (uint256) {
        uint256 result = sum + x;
        sum = result;
        return result;
    }
}