// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Sample {
    event EventInfo(string _eventName);
    function AddEvent(string memory _name) public {
        emit EventInfo(_name);
    }
}