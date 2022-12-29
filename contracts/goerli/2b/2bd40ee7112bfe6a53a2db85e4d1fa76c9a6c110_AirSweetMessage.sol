/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AirSweetMessage {
 // Define variable message of type Message
    struct Message{
        string id;
        string[] authors;
        string[] contents;
    }
    mapping(string => Message) messageMap;
    mapping(address => uint) countMap;
    mapping(address=>mapping(uint =>string)) messageIdMap;
    address _owner;
    constructor(){
        _owner  = msg.sender;
     }

     function getMessageLength(address  owner) public view returns(uint ){
        return countMap[owner];
     }

     function getMessageId(address owner,uint index)public view returns(string memory ){
         return messageIdMap[owner][index];
     }

     // Write function to change the value of variable Message
     function postMessage(string memory _id,string[] memory _authors,string[] memory _contents) public  returns (Message memory) {
         require(_authors.length >0,"authors is null");
         require(_contents.length >0,"contents is null");
         require(_authors.length == _contents.length,"message length error");

         if(messageMap[_id].authors.length >0){
            revert('message_id is existed');
         }
         messageIdMap[msg.sender][ countMap[msg.sender]] = _id;
         messageMap[_id] = Message({id:_id,authors:_authors,contents:_contents});
         return   messageMap[_id] ;
     }
    
     // Read function to fetch variable Message
     function getMessage(string memory id ) public view returns (Message memory ){
     return messageMap[id];
     }
    
     function getOwener() public view returns (address ){
         return msg.sender;
     }
    
}