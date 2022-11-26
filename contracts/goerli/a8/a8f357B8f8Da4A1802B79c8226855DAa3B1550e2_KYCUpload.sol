// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//will be using IPFS for file storage and uploads

contract KYCUpload {
    address[] private users;
    mapping(address => uint) private userMapping;
    mapping(address => userDetails) private userDetailMapping;
    address private owner;

    struct userDetails {
        string name;
        string homeAddress;
        string dateOfBirth;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getUserCount(address user) internal view returns (uint) {
        return userMapping[user];
    }

    function getOwnUserCount(address) public view returns (uint) {
        require(userMapping[msg.sender] > 0, "User does not exist.");
        return getUserCount(msg.sender);
    }

    function getUsers() public view returns (address[] memory) {
        return users;
    }

    function addUsers() public {
        if(getUserCount(msg.sender) == 0) {
            users.push(msg.sender);
            userMapping[msg.sender] = users.length;
        }
    }

    function setUserDetails(string memory name, string memory homeAddress, string memory dateOfBirth) public {
        if(getUserCount(msg.sender) == 0) {
            addUsers();
        }
        userDetailMapping[msg.sender] = userDetails(name, homeAddress, dateOfBirth);
    }

    function getUserDetails(address user) public view returns (string memory, string memory, string memory) {
        require(userMapping[user] > 0, "User does not exist. Register first.");
        return (userDetailMapping[user].name, userDetailMapping[user].homeAddress, userDetailMapping[user].dateOfBirth);
    }
}