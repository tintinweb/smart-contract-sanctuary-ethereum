// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

// contract address: 0xCCB5b84f3d21f3de8f2F1a988F60dfb290fd348c

contract HelloWorld {
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}