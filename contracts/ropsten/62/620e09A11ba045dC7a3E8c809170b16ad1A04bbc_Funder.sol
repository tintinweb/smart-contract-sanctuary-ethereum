/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

//SPDX-License-Identifier: None
pragma solidity 0.8.0;
contract Funder{

    struct User{
        string email;
    }

    struct ContentCreator{
        string email;
        string photo;
        string websiteLink;
        string social;
    }

    uint256 creatorCount;
    uint256 userCount;
    mapping(address => User) users;
    mapping(address => ContentCreator) contentCreators;
    mapping(address => bool) isUser;
    mapping(address => bool) isContentCreator;
    address[] public contentCreatorsArray; 

    function addUser(User memory user) public{
        require(
            isUser[msg.sender] == false && isContentCreator[msg.sender] == false, 
            "You are already registered");
        userCount++;
        users[msg.sender] = user;
        isUser[msg.sender] = true;
    }

    function addContentCreator(ContentCreator memory contentCreator) public{
        require(
            isContentCreator[msg.sender] == false &&  isUser[msg.sender] == false , 
            "You are already registered");
        creatorCount++;
        contentCreators[msg.sender] = contentCreator;
        contentCreatorsArray.push(msg.sender);
        isContentCreator[msg.sender] = true;
    }

    function getCreator(address creator) public view returns(ContentCreator memory contentCreator){
        return contentCreators[creator];
    }

    function getUser(address userAddress) public view returns(User memory user){
        return users[userAddress];
    }

    function getAllUser() public view returns(address[] memory){
        return contentCreatorsArray;
    }

    function donate(address payable creator) payable public{
        require(msg.value > 0, "The value should be greater than 0 ether");
        require(isUser[msg.sender] == true, "You should be a user to donate");
        require(isContentCreator[creator] == true, "You should donate to a Content Creator");
        creator.transfer(msg.value);
    }   
}