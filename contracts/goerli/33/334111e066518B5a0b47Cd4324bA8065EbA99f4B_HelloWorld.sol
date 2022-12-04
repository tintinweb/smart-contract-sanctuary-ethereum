//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld{

    event UpdateMessage(string oldMsg, string newMsg);

    string public message;

    constructor(string memory initMsg){
        message = initMsg;
    }

    function Update(string memory newMsg) public{
        string memory oldMsg = message;
        message = newMsg;
        emit UpdateMessage(oldMsg, newMsg);
    }

}