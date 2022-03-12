// SPDX-License-Identifier: MIT.
pragma solidity ^0.8.10;

// Este es el que se clona.
contract Store {
    string public _value;

    function setValue(string calldata newValue_) external {
        _value = newValue_;
    }

    function getValue() external view returns (string memory) {
        return _value;
    }
}