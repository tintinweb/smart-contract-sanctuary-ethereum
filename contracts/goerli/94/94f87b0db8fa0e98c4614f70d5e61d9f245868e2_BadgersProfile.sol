/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BadgersProfile {

    struct Experience {
        string company;
        string position;
        string description;
        uint256[] badges;
    }

    struct User {
        string name;
        Experience[] experiences;
    }
    
    mapping(address => User) public userMap;

    function createProfile(string memory displayName) public
    {
        User storage user = userMap[msg.sender];
        require(bytes(user.name).length == 0, "USER_EXISTS");

        user.name = displayName;
        userMap[msg.sender] = user;
    }

    function updateDisplayName(string memory displayName) public
    {
        User storage user = userMap[msg.sender];
        require(bytes(user.name).length != 0, "USER_NOT_EXIST");
        
        user.name = displayName;
        userMap[msg.sender] = user;
    }

    function removeProfile() public
    {
        User memory user = userMap[msg.sender];
        require(bytes(user.name).length != 0, "USER_NOT_EXIST");

        delete userMap[msg.sender];
    }

    function addExperience(string memory company, string memory position, string memory description) public 
    {
        User storage user = userMap[msg.sender];
        require(bytes(user.name).length != 0, "USER_NOT_EXIST");

        Experience memory experience = Experience(company, position, description, new uint256[](0));
        
        Experience[] storage experiences = user.experiences;
        experiences.push(experience);
        user.experiences = experiences;
    }

    function updateExperience(uint idx, string memory company, string memory position, string memory description) public  
    {
        User storage user = userMap[msg.sender];
        require(bytes(user.name).length != 0, "USER_NOT_EXIST");

        Experience[] storage experiences = user.experiences;
        require((idx >= 0) && (idx < experiences.length), "INDEX_OUT_OF_RANGE");

        Experience storage experience = experiences[idx];
        
        experience.company = company;
        experience.position = position;
        experience.description = description;

        experiences[idx] = experience;
        user.experiences = experiences;
    }

    function removeExperience(uint idx) public 
    {
        User storage user = userMap[msg.sender];
        require(bytes(user.name).length != 0, "USER_NOT_EXIST");

        Experience[] storage experiences = user.experiences;
        require((idx >= 0) && (idx < experiences.length), "INDEX_OUT_OF_RANGE");

        experiences[idx] = experiences[experiences.length-1];  // Order not preserved
        experiences.pop();
    }

    function addBadgeToExperience(address recipientAddress, uint expIdx, uint256 tokenId) public 
    {
        User memory sender = userMap[msg.sender];
        require(bytes(sender.name).length != 0, "SENDER_NOT_REGISTERED");

        User storage recipient = userMap[recipientAddress];
        require(bytes(recipient.name).length != 0, "RECIPIENT_NOT_EXIST");

        Experience[] storage experiences = recipient.experiences;
        require((expIdx >= 0) && (expIdx < experiences.length), "INDEX_OUT_OF_RANGE");

        Experience storage experience = experiences[expIdx];
        uint256[] storage badges = experience.badges;

        badges.push(tokenId);
        experience.badges = badges;
        experiences[expIdx] = experience;
        recipient.experiences = experiences;
    }
    
}