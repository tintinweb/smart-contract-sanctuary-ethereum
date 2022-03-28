//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/// @title EventLog
contract EventLog {

    event LogEvent(bytes32 indexed contractNameHash, bytes4 indexed eventName, address indexed contractAddress, bytes data);

    constructor() {
    }

    function logEvent(bytes32 contractNameHash, bytes4 eventName, address contractAddress, bytes memory data) public {
        emit LogEvent(contractNameHash, eventName, contractAddress, data);
    }
}