//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract HelloWorld {

    event UpdatedMessage(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory _message) public {
        string memory oldMsg = message;
        message = _message;
        emit UpdatedMessage(oldMsg, _message);
    }

}