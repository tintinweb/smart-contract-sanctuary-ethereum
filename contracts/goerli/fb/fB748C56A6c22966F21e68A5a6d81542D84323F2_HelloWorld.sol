// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld{

    string public message = "hello World!";
    event UpdateMessages(string indexed oldstr, string indexed newstr);

    // constructor(string memory initMessage){
    //     message = initMessage;
    // }

    function updateMessage(string memory _message) external {
        message = _message;
        emit UpdateMessages(message, _message);
    }
}