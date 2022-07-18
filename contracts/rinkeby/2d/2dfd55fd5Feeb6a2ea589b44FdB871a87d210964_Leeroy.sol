// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Leeroy {

    mapping (address => uint256) userIndex;
    mapping (address => bool) isUserKilled;
    
    event annMade(
        address announcer,
        uint256 userIndex,
        uint256 timeAnnounced,
        string topic,
        string description,
        string flair,
        string[] media
    );

   function announce(string calldata _topic, string calldata _annText, string calldata _flair, string[] calldata _media) public {  
       require(!isUserKilled[msg.sender]);
       emit annMade(msg.sender,userIndex[msg.sender]++,block.timestamp,_topic,_annText,_flair,_media);
  }
  
   function announcementIndex(address _recipient) public view returns (uint256){
        return userIndex[_recipient];
  }  
   function killGet(address _recipient) public view returns (bool){
        return isUserKilled[_recipient];
  }  

   function killUser() public{
        isUserKilled[msg.sender] = true;
  }  
  



}