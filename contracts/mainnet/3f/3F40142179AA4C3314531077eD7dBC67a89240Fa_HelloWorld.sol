/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract HelloWorld {
    string private value;

    function setValue(string memory _value) public {
        value = _value;
    }

    function getValue() public view returns (string memory) {
        return value;
    }
}