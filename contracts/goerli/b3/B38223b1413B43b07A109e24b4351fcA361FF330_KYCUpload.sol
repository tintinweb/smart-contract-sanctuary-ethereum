// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//will be using IPFS for file storage and uploads

contract KYCUpload {
    address[] private users;
    mapping(address => uint) private userMapping;
    address private owner;

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

    function getOwnUserCount() public view returns (uint) {
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
}