// SPDX-License-Identifier: MI
pragma solidity ^0.8.9;

contract PublicPost {
    string public message;
    address public owner;

    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
    }

    function store(string memory _message) public {
        require(msg.sender == owner, "You don't have permission to post a message here.");
        message = _message;
    }
}