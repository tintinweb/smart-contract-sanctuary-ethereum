/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {

    struct LastMessage {
        address submitter;
        string message;
    }

    LastMessage lastMessage;

    // Mapping strings from address
    mapping(address => string[]) public accountMsgMap;

    constructor() {
        lastMessage.submitter = msg.sender;
        lastMessage.message = "Hello World";
    }

    event Log(address submitter, string message);

    // Push the message to the array of the sender
    // Update the last message struct
    function updateMessage(string memory _msg) public {
        accountMsgMap[msg.sender].push(_msg);
        lastMessage.submitter = msg.sender;
        lastMessage.message = _msg;
    }

    //returns the string at index i for a given user
    function getMessage(address _user, uint _index) public view returns (string memory) {
        require(accountMsgMap[_user].length > _index, "Index for the provided address does not exist");
        return accountMsgMap[_user][_index];
    }

    //returns the latest message and the address that submitted it
    function latestMessage() public returns (address, string memory) {
        emit Log(lastMessage.submitter, lastMessage.message);
        return (lastMessage.submitter, lastMessage.message);
    }

}