/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract AuthedMessengerV2 {
    struct authedMessage {
        string msg;
        uint256 timestamp;
        string signature;
        uint256 sigNonce;
    }

    authedMessage[] messages;

    function sendMessage(
        string memory _msg,
        string memory signature,
        uint256 sigNonce
    ) public {
        messages.push(
            authedMessage({
                msg: _msg,
                timestamp: block.timestamp,
                signature: signature,
                sigNonce: sigNonce
            })
        );
    }

    function readMessages(uint256 offset)
        public
        view
        returns (authedMessage[16] memory)
    {
        uint256 maxLen = messages.length;
        authedMessage[16] memory lastMessages;

        for (uint256 i = 0; i < maxLen - offset; i++) {
            if (i == 16) {
                break;
            }
            lastMessages[i] = messages[i + offset];
        }
        return lastMessages;
    }

    function readAllMessages() public view returns (authedMessage[] memory) {
        return messages;
    }
}