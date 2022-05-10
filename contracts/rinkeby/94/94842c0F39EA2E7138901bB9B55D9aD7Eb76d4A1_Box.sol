// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Box {
    uint256 public value;

    function initialize(uint256 _value) public {
        value = _value;
    }
}