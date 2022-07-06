// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HellowWorld{
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    // constructor runs only once when the smart contract is created in the blockchain
    constructor (string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}