/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardMessengerV3Test3 {
    struct Message {
        address sender;
        uint256 blockDate;
        string text;
        string[] attachments;
    }

    mapping(address => Message[]) private messages;
    address[] messageRecipients;
    mapping(address => address[]) messageSenders;

    function sendPublicMessage(
        address _recipient,
        string memory _text,
        string[] memory _attachments
    ) public {
        Message[] storage recipientMessages = messages[_recipient];
        recipientMessages.push(
            Message({
                sender: msg.sender,
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
        Message[] storage ownMessages = messages[msg.sender];
        Message[] memory senderMessages;

        uint256 messagesIndex = 0;
        for (uint256 i = 0; i < ownMessages.length; i++) {
            Message storage thisMessage = ownMessages[i];
            if (thisMessage.sender == senderAddress) {
                senderMessages[messagesIndex] = thisMessage;
                messagesIndex++;
            }
        }

        return senderMessages;
    }

    function readMessages(address senderAddress, uint256 offset)
        public
        view
        returns (Message[64] memory)
    {
        Message[64] memory result;
        Message[] storage ownMessages = messages[msg.sender];

        uint256 messagesIndex = 0;
        for (uint256 i = 0; i < 64; i++) {
            if (i + offset < ownMessages.length) {
                Message storage message = ownMessages[i + offset];
                if (message.sender == senderAddress) {
                    result[messagesIndex] = message;
                    messagesIndex++;
                    continue;
                }
            }

            string[] memory emptyAttachments;
            result[i] = Message({
                sender: address(0),
                blockDate: 0,
                text: "",
                attachments: emptyAttachments
            });
        }
        return result;
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

    function getMessagesLength(address senderAddress)
        public
        view
        returns (uint256)
    {
        Message[] storage ownMessages = messages[msg.sender];

        uint256 messagesIndex = 0;
        for (uint256 i = 0; i < ownMessages.length; i++) {
            Message storage thisMessage = ownMessages[i];
            if (thisMessage.sender == senderAddress) {
                messagesIndex++;
            }
        }

        return messagesIndex;
    }
}