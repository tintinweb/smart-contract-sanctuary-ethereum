// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

contract HelloWorld {
    string public message;

    constructor() public {
        message = "Hello, world!";
    }

    function update(string memory newMessage) public {
        message = newMessage;
    }
}