// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Simple {
    string message = "Hello World";

    function getMessage() external view returns(string memory) {
        return message;
    }

    function setMessage(string calldata _message) external {
        message = _message;
    }
}