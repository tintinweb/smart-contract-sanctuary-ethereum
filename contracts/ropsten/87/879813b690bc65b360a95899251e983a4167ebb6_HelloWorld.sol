// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract HelloWorld {

    // string message = "Hello world";
    // string[] messages = ["Hello world"];
    mapping(address => string[]) messages;
    address latestAddress;

    event Message(string message);

    // function hello() public pure returns (string memory) {
    //     return "Hello world";
    // }

    // // Emitting an event makes function neither view nor pure
    // function hello() public returns (string memory) {
    //     emit Message("Hello world");
    //     return "Hello world";
    // }

    // function hello() public returns (string memory) {
    //     emit Message(messages[messages.length - 1]);
    //     return messages[messages.length - 1];
    // }
    
    function hello() public returns (string memory) {
        if (messages[msg.sender].length == 0) {
            messages[msg.sender].push("Hello world");
        }
        emit Message(messages[msg.sender][messages[msg.sender].length - 1]);
        return messages[msg.sender][messages[msg.sender].length - 1];
    }

    // function updateMessage(string memory newMessage) public {
    //     messages.push(newMessage);
    // }

    function updateMessage(string memory newMessage) public {
        messages[msg.sender].push(newMessage);
        latestAddress = msg.sender;
    }

    function getMessage(address user, uint i) view public returns (string memory) {
        return messages[user][i];
    }

    function latestMessage() view public returns (string memory, address) {
        return (messages[latestAddress][messages[latestAddress].length - 1], latestAddress);
    }
}