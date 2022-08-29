// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string Message;
    
    string[] MyLength;

    constructor(string memory message) public{
        Message = message;
        MyLength.push(message);
    }

    function getMessage() public view returns(string memory){
        return Message;
    }

    function UpdateMessage(string memory message) public{
        emit UpdatedMessages(Message, message);
        Message = message;
        MyLength.push(Message);
    }

    function getMy() public view returns(string[] memory){
        return MyLength;
    }


}