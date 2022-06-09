// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Dummy {
    event ValueChanged(string oldValue, string newValue);
    string public value;

    constructor(string memory _value) {
        value = _value;
    }

    function setValue(string memory _value) public {
        emit ValueChanged(value, _value);
        value = _value;
    }
}