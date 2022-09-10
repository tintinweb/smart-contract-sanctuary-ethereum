/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test {
    address public owner;
    uint256 public balance;

    struct User {
        bool registered;
        uint id;
        string name;
    }

    mapping (uint => User) internal users;
    uint[] userIDs;

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance += msg.value;
    }

    function withdraw(uint amount, address payable destAddr) public {
        destAddr.transfer(amount);
        balance -= amount;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function addUser(uint id, string memory name) public {
        if (users[id].registered)
            return;

        users[id].registered = true;
        users[id].id = id;
        users[id].name = name;
        userIDs.push(id);
    }

    function getUserIDs() public view returns(uint[] memory) {
        return userIDs;
    }

    function getUsers() public view returns(User[] memory) {
        User[] memory userList = new User[](userIDs.length);
        for (uint i = 0; i < userIDs.length; i++)
            userList[i] = users[userIDs[i]];
        return userList;
    }
}