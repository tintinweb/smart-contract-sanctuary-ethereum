/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract AnonymousMessengerV2 {
    struct message {
        string msg;
        uint256 timestamp;
    }

    message[] messages;

    function sendMessage(string memory _msg) public {
        messages.push(message({msg: _msg, timestamp: block.timestamp}));
    }

    function readMessages(uint256 offset)
        public
        view
        returns (message[16] memory)
    {
        uint256 maxLen = messages.length;
        message[16] memory lastMessages;

        for (uint256 i = 0; i < maxLen - offset; i++) {
            if (i == 16) {
                break;
            }
            lastMessages[i] = messages[i + offset];
        }
        return lastMessages;
    }

    function readAllMessages() public view returns (message[] memory) {
        return messages;
    }
}