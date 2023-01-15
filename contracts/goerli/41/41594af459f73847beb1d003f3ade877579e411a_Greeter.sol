/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Greeter {
    string public message;
    string[] public messageArr;
    address public owner;

    constructor() {
        owner = msg.sender;
        message = "This is the first message!";
        messageArr.push(message);
    }

    function setMessage(string memory _message) external {
        message = _message;
        messageArr.push(message);
    }

    function getMessage() external view returns (string memory) {
        return message;
    }

    function getMessages() external view returns (string[] memory) {
        return messageArr;
    }
}