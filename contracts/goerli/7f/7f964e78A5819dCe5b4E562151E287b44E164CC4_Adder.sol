//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Adder {
    uint256 public value;

    function initialize(uint256 value_) external {
        value = value_;
    }

    function add(uint256 value_) external {
        value += value_;
    }
}