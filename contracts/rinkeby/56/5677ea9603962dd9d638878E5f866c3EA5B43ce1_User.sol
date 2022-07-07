// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract User {
    mapping(address => int8) public userLimit;
    mapping(string => address) public users;

    function createUser(string calldata username) public {
        require(userLimit[msg.sender] == 0, "You can only have 1 account");
        require(users[username] == address(0), "There is already a user with this address");
        users[username] = msg.sender;
        userLimit[msg.sender] = 1;
    }

    function setUsername(string calldata username) public {
        require(userLimit[msg.sender] < 2, "User limit exceeded");
        require(users[username] == address(0), "There is already a user with this address");
        users[username] = msg.sender;
        userLimit[msg.sender] = userLimit[msg.sender] + 1;
    }
}