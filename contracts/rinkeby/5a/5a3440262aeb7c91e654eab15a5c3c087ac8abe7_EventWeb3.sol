// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventWeb3 {
    uint256 public value = 20;
    event ValueChanged(uint256 indexed newValue);

    function updateValue(uint256 _newValue) public{
        value = _newValue;
        emit ValueChanged(_newValue);
    }
}