// SPDX-License-Identifier: MIT


pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

contract Sharer {

    struct MessageRequest {
        address sender;
        bytes encReceiver;
    }

    //stores all message request
    //receivers needs to go through all requests
    //to know if he is the reciepient
    MessageRequest[] public MessageRequests;
    
    mapping(address => bytes) public publicKeys;
    mapping(address => bytes) public privateKeys;

    function addPublicKey(bytes memory b) public{
        publicKeys[msg.sender] = b;
    }

    function getPubKey(address add) public view returns(bytes memory){
        return publicKeys[add];
    }

    function addEncPrivateKey(bytes memory b) public{
        privateKeys[msg.sender] = b;
    }

    function getEncPrivateKey(address add) public view returns(bytes memory){
        return privateKeys[add];
    }

    function checkUser() public view returns(bool){
        if(publicKeys[msg.sender].length> 0){
            return true;
        }
        else{
            return false;
        }
    }

    function IwantToContact(bytes memory encryptedMessage) public {
        MessageRequests.push(MessageRequest(msg.sender, encryptedMessage));
    }

    function getMessageRequest(uint id) public view returns(
        address sender,
        bytes memory encReceiver
    )
    {
        sender = MessageRequests[id].sender;
        encReceiver = MessageRequests[id].encReceiver;
    }

    function getMessageRequestLength() public view returns(uint)
    {
        return MessageRequests.length;
    }

}