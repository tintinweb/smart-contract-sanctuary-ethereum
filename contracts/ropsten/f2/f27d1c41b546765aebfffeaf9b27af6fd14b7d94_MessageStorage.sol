/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract MessageStorage {
    address payable public owner_wallet;
    uint256 public msgCount = 0;
    mapping(uint256 => Message) public message;

    modifier onlyOwner() {
        require(msg.sender == owner_wallet);
        _;
    }
    constructor(){
        owner_wallet = msg.sender;
    }

    struct Message{
        uint256 id;
        string text;
        string fileName;
        string fileType;
        string fileHash;
        string msgSize;
        string datetime;
    }

    function addMessage(string memory text, string memory fileName, string memory fileType, string memory fileHash, string memory msgSize, string memory datetime) public payable{
        
        owner_wallet.transfer(msg.value);

        
        message[msgCount] = Message(msgCount, text, fileName, fileType, fileHash, msgSize, datetime);
        msgCount += 1;
        // sendCommission(owner_wallet);
    }

    function addMultipleMessages(string[] memory text, string[] memory fileName, string[] memory fileType, string[] memory fileHash, string[] memory msgSize, string memory datetime) public {
        for(uint i = 0; i< text.length; i++)
        {
            message[msgCount] = Message(msgCount, text[i], fileName[i], fileType[i], fileHash[i], msgSize[i], datetime);
            msgCount += 1;
        }
    }

    function getMessageCount() public view returns (uint256) {
        return msgCount;
    }

    function get(uint256 index) public view returns (Message memory){
        return message[index];
    }

    // function sendCommission(address payable _address) public payable {
    //     _address.transfer(msg.value);
    // }

    function setOwnerWallet(address payable _owner_wallet)  onlyOwner public {
        owner_wallet = _owner_wallet;
    }
    
    function getOwnerWallet() public view returns (address) {
        return owner_wallet;
    }
}