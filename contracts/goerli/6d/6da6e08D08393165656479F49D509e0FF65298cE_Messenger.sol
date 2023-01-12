// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Messenger {
    struct Chat{
        address sender;
        string message;
        address owner;
    }
    struct User {
        string username;
        string email;
        string password;
        address[] friends;
        string[] friendsUserName;
        address owner;
        uint256 amount;
        bool isUserLoggedIn;
    }
    mapping (uint256 => User) public users;
    mapping (uint256 => Chat) public chats;
    uint256 public noOfUsers = 0;
    uint256 public conversationId = 0;
    function createAccount(string memory username,string memory email,string memory 
    password,address owner)public returns (uint256){
        User storage user = users[noOfUsers];
        user.username = username;
        user.email = email;
        user.password = password;
        user.owner = owner;
        noOfUsers++;
        return noOfUsers - 1;
    }
    
    function login(address owner, string memory _password)public returns (bool){
        if (
            keccak256(abi.encodePacked(users[noOfUsers].password)) == keccak256(abi.encodePacked(_password))) {
            users[noOfUsers].isUserLoggedIn = true;
            return users[noOfUsers].isUserLoggedIn;
        } 
        else {
            return false;
        }
    }

    function checkIsUserLogged() public view returns (bool) {
        return (users[noOfUsers].isUserLoggedIn);
    }

    function logout() public {
        users[noOfUsers].isUserLoggedIn = false;
    }
    function sendMessage(address owner,string memory message) public returns (uint256){
        Chat storage chat = chats[conversationId];
        chat.sender = msg.sender;
        chat.message = message;
        chat.owner = owner;
        conversationId++;
        return conversationId - 1;
    }
    function sendMoney()  public payable {
        uint256 Amount = msg.value;
        User storage user = users[noOfUsers];
        (bool sent,) = payable(user.owner).call{value: Amount}("");
        if(sent) {
            user.amount = user.amount + Amount;
        }
    }
    function getTotalAmount(address sender)public returns (uint256){
        return users[noOfUsers].amount;
    }

}