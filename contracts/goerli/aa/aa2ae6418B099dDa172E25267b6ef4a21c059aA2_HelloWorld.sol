// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract HelloWorld {
    string public message;
    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory _newMessage) public {
        message = _newMessage;
    }

}