// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error UserNotFound();

contract Crud {
    struct User {
        uint256 id;
        string name;
    }

    uint256 private nextId = 1;

    User[] public users;

    function create(string memory name) public {
        users.push(User(nextId, name));
        nextId++;
    }

    function read(uint256 id) public view returns (uint256, string memory) {
        uint256 i = find(id);
        return (users[i].id, users[i].name);
    }

    function update(uint256 id, string memory name) public {
        uint256 i = find(id);
        users[i].name = name;
    }

    function deleteId(uint256 id) public {
        uint256 i = find(id);
        delete users[i];
    }

    function find(uint256 id) public view returns (uint256) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == id) {
                return i;
            }
        }
        revert UserNotFound();
    }

    function getNextId() public view returns (uint256) {
        return nextId;
    }
}