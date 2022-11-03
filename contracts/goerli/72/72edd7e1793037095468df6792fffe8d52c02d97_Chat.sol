/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

struct Message {
    address from;
    string text;
}


contract Chat {
    mapping (address => Message[]) private _messagesMap;

    function sendMessage(address from, address to, string memory message) public {
        _messagesMap[to].push(Message(
            from,
            message
        ));
    }

    function getMessages(address to) public view returns (Message[] memory) {
        return _messagesMap[to];
    }
}