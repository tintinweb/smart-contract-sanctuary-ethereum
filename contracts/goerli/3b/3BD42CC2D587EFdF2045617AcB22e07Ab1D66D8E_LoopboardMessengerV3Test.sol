/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardMessengerV3Test {
    struct Message {
        bool exists;
        uint256 blockDate;
        string text;
        string[] attachments;
    }

    mapping(address => mapping(address => Message[])) private messages;
    address[] messageRecipients;
    mapping(address => address[]) messageSenders;

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

        bool isExistingRecipient = false;
        for (uint256 index = 0; index < messageRecipients.length; index++) {
            if (messageRecipients[index] != _recipient) {
                isExistingRecipient = true;
            }
        }
        if (!isExistingRecipient) {
            messageRecipients.push(_recipient);
        }
        bool isExistingSender = false;
        for (
            uint256 index = 0;
            index < messageSenders[_recipient].length;
            index++
        ) {
            if (messageSenders[_recipient][index] != msg.sender) {
                isExistingSender = true;
            }
        }
        if (!isExistingSender) {
            messageSenders[_recipient].push(msg.sender);
        }
    }

    function readAllMessages(address senderAddress)
        public
        view
        returns (Message[] memory)
    {
        return messages[msg.sender][senderAddress];
    }

    function readMessages(address senderAddress, uint256 offset)
        public
        view
        returns (Message[64] memory)
    {
        Message[64] memory ids;
        for (uint256 i = 0; i < 64; i++) {
            if (i + offset < messages[msg.sender][senderAddress].length) {
                ids[i] = messages[msg.sender][senderAddress][i + offset];
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

    function getRecipients() public view returns (address[] memory) {
        return messageRecipients;
    }

    function getSenders(address recipient)
        public
        view
        returns (address[] memory)
    {
        return messageSenders[recipient];
    }
}