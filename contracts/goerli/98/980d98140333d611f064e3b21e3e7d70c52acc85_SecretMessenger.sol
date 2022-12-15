/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SecretMessenger {

    struct Envelope {
        bytes encodedMessage;
    }
    // receipient -> senders 
    mapping(address => address[]) private inbox;
    // receipient -> sender -> number of Messages
    mapping(address => mapping(address => uint256)) private numMessagesFrom;
    // receipient -> sender -> messageId -> Envelope
    mapping(address => mapping(address => mapping(uint256 => Envelope))) private receipient;

    event MessageSent(address from, address to, uint256 messageId);

    modifier hasMessages(address from){
        require(numMessagesFrom[msg.sender][from] != 0, "There are no messages from this sender");
        _;
    }

    function sendMessage(address to, string calldata message) public {

        uint256 messageId = numMessagesFrom[to][msg.sender];
        bytes32 hashKey = keccak256(abi.encodePacked(msg.sender,to,message));

        receipient[to][msg.sender][messageId] = Envelope(abi.encode(hashKey, message, msg.sender));
        emit MessageSent(msg.sender, to, messageId);

        numMessagesFrom[to][msg.sender] += 1;
        inbox[to].push(msg.sender);
    }
    function checkInbox() external view returns (address[] memory) {
        return inbox[msg.sender];
    }
    function checkNumberOfMessagesFrom(address from) public view returns (uint256) {
        return numMessagesFrom[msg.sender][from];
    }
    function latestMessageIdFrom(address from) internal view hasMessages(from) returns (uint256) {
        return numMessagesFrom[msg.sender][from]-1;
    }
    function latestMessageFrom(address from) external view hasMessages(from) returns (bytes memory) {
        return receipient[msg.sender][from][latestMessageIdFrom(from)].encodedMessage;
    }
    function readSecretMessage(address from, uint256 messageId) external view hasMessages(from) returns (bytes memory) {
        return receipient[msg.sender][from][messageId].encodedMessage;
    }
    function decodeMessage(bytes memory data) public view returns (string memory) {
        (bytes32 hashKey, string memory message, address from) = abi.decode(data, (bytes32, string, address));  
        require(keccak256(abi.encodePacked(from,msg.sender,message)) == hashKey, "The encoded message was not for you.");
        return message;          
    }
}