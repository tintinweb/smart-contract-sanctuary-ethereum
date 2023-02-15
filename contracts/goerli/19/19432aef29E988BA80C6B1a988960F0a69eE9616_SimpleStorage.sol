// Solidity version
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract definition
contract SimpleStorage {
    // State variable to store the string value
    string private value;

    // Function to set the string value
    function setValue(string memory _value) public {
        value = _value;
    }

    // Function to get the string value
    function getValue() public view returns (string memory) {
        return value;
    }
}