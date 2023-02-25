// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Chat {
    struct user{
        string name;
        friend[] friendList;
    }

    struct friend{
        address publicKey;
        string name;
    }

    struct message{
        string msg;
        address sender;
        uint256 timestamp;
        
    }

    struct allUsers{
        string name;
        address accountId;

    }

    allUsers[] getAllUsers;

    mapping(address => user) userList;
    mapping(bytes32 => message[]) allMessages;

    function getAppUsers() public view returns(allUsers[]memory){
        return getAllUsers; 
    }

    function checkUser(address publicKey) public view returns(bool) {
        return bytes(userList[publicKey].name).length > 0;
    }

    function createAccount(string calldata name) external{
        require(checkUser(msg.sender) == false, "User exists");
        require(bytes(name).length > 0, "Username cannot be empty");
        userList[msg.sender].name = name;
        getAllUsers.push(allUsers(name,msg.sender));
    }

    function fetchUsername(address publicKey) external view returns(string memory) {
        require(checkUser(publicKey), "User is not available");
        return userList[publicKey].name;
    }

    function addFriend(address friend_key, string calldata name) external{
        require(checkUser(msg.sender), "Create an account");
        require(checkUser(friend_key), "User not Found !!!");
        require(msg.sender != friend_key, "Users cannot add themeselves as friends");
        require (checkAlreadyFriends (msg.sender, friend_key)== false, "These users are already friends");


        _addFriend (msg.sender, friend_key, name);
        _addFriend(friend_key, msg.sender, userList[msg.sender].name);
    }

    function checkAlreadyFriends(address publicKey1, address publicKey2) internal view returns(bool) {
        if(userList[publicKey1].friendList.length > userList[publicKey2].friendList.length) {
        address tmp = publicKey1;
        publicKey1= publicKey2;
        publicKey2 = tmp; 
    }
        for(uint256 i = 0; i < userList[publicKey1].friendList.length; i++){
        if(userList[publicKey1].friendList[i].publicKey == publicKey2)return true;
    }
        return false;
    }

    function _addFriend (address mySelf, address friend_key, string memory name) internal{
        friend memory newFriend = friend (friend_key, name);
        userList[mySelf].friendList.push(newFriend);
        
    }

    function showFriends() external view returns(friend[] memory){
        return userList[msg.sender].friendList;
    }

    function getChat(address publicKey1 , address publicKey2) internal pure returns(bytes32){
        if(publicKey1 < publicKey2){
            return keccak256(abi.encodePacked(publicKey1, publicKey2));
        }else return keccak256(abi.encodePacked(publicKey2, publicKey2));
    }

    function sendMessage(address friend_key, string calldata _msg) external{
        require(checkUser(msg.sender), "Account not Created");
        require(checkUser(friend_key), "User is not available");
        require(checkAlreadyFriends(msg.sender, friend_key), "You are not friend with this user");

        bytes32 chatCode = getChat(msg.sender, friend_key);
        message memory newMessage = message(_msg,msg.sender,block.timestamp);
        allMessages[chatCode].push(newMessage);
    }

    function readMessage(address friend_key) external view returns(message[] memory){
        bytes32 chatCode = getChat(msg.sender, friend_key);
        return allMessages[chatCode]; 
    }
}