// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract SimpleMapping {
    mapping(address => bytes32) public storedData;

    function storeData(bytes32 _data) public {
        storedData[msg.sender] = _data;
    }
}