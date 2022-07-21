// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract aNounSer {

    //Z2FwZXIuZXRo
    //Index of total messages sent by an address
    mapping (address => uint256) userIndex;

    //Store of Addresses that users have terminated.
    mapping (address => bool) isUserKilled;



    //Data parameters for announcements.
    event annMade(
        address announcer,
        uint256 userIndex,
        uint256 timeAnnounced,
        string annTitle,
        string annText,
        string[] flair,
        string[] media
    );

    event userKilled(
        bool status
    );


     /*
     * @param _annTopic string is the topic of the announcement.
     * @param string _annText is the actual message content
     * @param string[] _flair is for tags to filter messages by, ie. "Airdrop"
     * @param string[] _media is for links. ipfs://...
     */
    function announce(string calldata _annTitle, string calldata _annText, string[] calldata _flair, string[] calldata _media) public {  
       require(!isUserKilled[msg.sender]);
       emit annMade(msg.sender,userIndex[msg.sender]++,block.timestamp,_annTitle,_annText,_flair,_media);
       
    }

    /* In the case of a compromise, users can swiftly kill an address and prevent them from
    making further announcements. As a security precaution these accounts will NEVER be able to
    make announcements ever again.
     */
    function killUser() public{
        require(!isUserKilled[msg.sender]);
        isUserKilled[msg.sender] = true;
        emit userKilled(true);
    }  

    //Returns an addresses current message count. 
    function announcementIndex(address _user) public view returns (uint256){
        return userIndex[_user];
    }  

    //Returns users status. True = Dead.
    function killGet(address _user) public view returns (bool){
        return isUserKilled[_user];
    }  

}