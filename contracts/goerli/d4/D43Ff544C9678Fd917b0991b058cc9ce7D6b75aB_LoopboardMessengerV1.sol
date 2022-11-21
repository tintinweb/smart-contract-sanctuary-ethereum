/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardMessengerV1 {
    struct Message {
        uint256 blockDate;
        string text;
        string[] attachments;
    }

    mapping(address => mapping(address => Message[])) private messages;

    function sendPublicMessage(
        address _recipient,
        string memory _text,
        string[] memory _attachments
    ) public {
        messages[_recipient][msg.sender].push(
            Message({
                blockDate: block.timestamp,
                text: _text,
                attachments: _attachments
            })
        );
    }

    function readMessages(address _messageSender, uint256 _offset)
        public
        view
        returns (Message[16] memory)
    {
        uint256 maxLen = messages[msg.sender][_messageSender].length;
        Message[16] memory lastMessages;

        for (uint256 i = 0; i < maxLen - _offset; i++) {
            if (i == 16) {
                break;
            }
            lastMessages[i] = messages[msg.sender][_messageSender][i + _offset];
        }
        return lastMessages;
    }
}