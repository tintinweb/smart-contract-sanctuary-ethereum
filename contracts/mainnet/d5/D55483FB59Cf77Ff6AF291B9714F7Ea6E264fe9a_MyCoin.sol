/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MyCoin {
    string private nameValue;

    function setValue(string memory _value) public {
        nameValue = _value;
    }

    function getValue() public view returns (string memory) {
        return nameValue;
    }
}