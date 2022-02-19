// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract messenger {

    mapping(address => string) userToPubKey;

    function setPublicKey(string memory _publicKey) public {
        userToPubKey[msg.sender] = _publicKey;
    }

    function publicKey(address user) public view returns(string memory){
        return userToPubKey[user];
    }


    mapping(address => uint256) messageCounter;
    
    event NewMessage(address from, address to, uint256 toMessageIndex, string subject, string message);

    function sendMessage(
        address to,
        string memory subject,
        string memory message
    ) public {
        messageCounter[to] += 1;
        emit NewMessage(msg.sender, to, messageCounter[to], subject, message);
    }
}