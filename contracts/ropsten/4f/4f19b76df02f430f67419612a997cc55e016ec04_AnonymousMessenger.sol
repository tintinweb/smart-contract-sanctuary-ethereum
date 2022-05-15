/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract AnonymousMessenger {
    string[] messages;

    function sendMessage(string memory _msg) public {
        messages.push(_msg);
    }

    function readMessages(uint256 offset)
        public
        view
        returns (string[16] memory)
    {
        uint256 maxLen = messages.length;
        string[16] memory lastMessages;

        for (uint256 i = 0; i < maxLen - offset; i++) {
            if (i == 16) {
                break;
            }
            lastMessages[i] = messages[i + offset];
        }
        return lastMessages;
    }

    function readAllMessages() public view returns (string[] memory) {
        return messages;
    }
}