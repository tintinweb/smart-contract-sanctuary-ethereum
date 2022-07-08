//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Greeter {
    string public message;

    constructor() {
        message = 'I was just deployed';
    }

    function setMessage(string memory _message) external {
        message = _message;
    }
}