/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract VerySimpleContract {
    event ValueStored(address indexed sender, string value);

    mapping(address => mapping(string => bool)) private storedValues;

    function storeValue(string memory value) external {
        storedValues[msg.sender][value] = true;
        emit ValueStored(msg.sender, value);
    }
}