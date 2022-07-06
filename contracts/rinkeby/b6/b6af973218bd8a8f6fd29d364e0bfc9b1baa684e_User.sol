/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

contract User {
    address public owner;
    mapping(address => int8) public userLimit;
    mapping(string => address) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "This can only be called by the contract owner!");
        _;
    }

    constructor () {
        owner = msg.sender;
    }

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
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}