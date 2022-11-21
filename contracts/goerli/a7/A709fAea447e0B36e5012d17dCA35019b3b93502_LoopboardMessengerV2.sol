/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardMessengerV2 {
    struct Message {
        bool exists;
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
                exists: true,
                blockDate: block.timestamp,
                text: _text,
                attachments: _attachments
            })
        );
    }

    function readAllMessags(address adminAddress)
        public
        view
        returns (Message[] memory)
    {
        return messages[msg.sender][adminAddress];
    }

    function readMessages(address adminAddress, uint256 offset)
        public
        view
        returns (Message[64] memory)
    {
        Message[64] memory ids;
        for (uint256 i = 0; i < 64; i++) {
            if (i + offset < messages[msg.sender][adminAddress].length) {
                ids[i] = messages[msg.sender][adminAddress][i + offset];
            } else {
                string[] memory emptyAttachments;
                ids[i] = Message({
                    exists: false,
                    blockDate: 0,
                    text: "",
                    attachments: emptyAttachments
                });
            }
        }
        return ids;
    }
}