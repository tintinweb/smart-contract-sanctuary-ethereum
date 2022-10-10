/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Counter {
    uint256 public state;

    uint256 public incrs;
    uint256 public decrs;

    function increment(uint256 delta) external {
        require(delta != 0, "Invalid delta");
        state += delta;

        incrs ++;
    }

    function decrement(uint256 delta) external {
        require(delta != 0 && delta <= state, "Invalid delta");
        state -= delta;

        decrs --;
    }
}