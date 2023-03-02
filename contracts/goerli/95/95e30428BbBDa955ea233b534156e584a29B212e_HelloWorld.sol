// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld {
    string public message = "Hello World";

    function update(string memory _message) public {
        message = _message;
    }

    function readMessage() public view returns (string memory) {
        return message;
    }
}