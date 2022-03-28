// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract demo {
    string value;

    constructor() {
        value = "myValue";
    }
    function get() public view returns(string memory) {
        return value;
    }
    function set(string memory newValue) public {
        value = newValue;
    }
}