// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

contract HelloWorld {
    uint256 public value;
    
    constructor(uint256 _value) {
        require(_value != 0);
        value = _value;
    }
}