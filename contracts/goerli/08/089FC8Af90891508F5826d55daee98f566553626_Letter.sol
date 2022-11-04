/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Letter {
    address public owner;
    struct Message {
        address sender;
        string content;
    }

    Message[] public messages;

    constructor() {
        owner = msg.sender;
    }

    event Sent(
        address sender,
        string content,
        uint time
    );

    function create(string memory _content) public {
        require(bytes(_content).length > 0, "You did not enter content");
        messages.push(Message(msg.sender, _content));
        emit Sent(msg.sender, _content, block.timestamp);
    }

    function getMessage() public view returns(Message[] memory) {
        return messages;
    }
}