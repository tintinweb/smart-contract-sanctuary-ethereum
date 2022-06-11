// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;

contract HelloWorld{
    
    event UpdateMessages(string oldStr, string newStr);
    
    string public message;

    constructor(string memory initMessage){
        message = initMessage;
    }

    function update(string memory _message) public {
        string memory oldMsg = message;
        message = _message;
        emit UpdateMessages(oldMsg, _message);
    }
}