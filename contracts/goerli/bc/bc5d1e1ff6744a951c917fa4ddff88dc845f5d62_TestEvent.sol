/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.12;

contract TestEvent {

    event PersonAdded(address user, string name, uint8 age);

    struct Person {
        string name;
        uint8 age;
    }

    mapping(address => Person) private userIds;

    function setNewUser(address user, string memory name, uint8 age) public {
        userIds[user].name = name;
        userIds[user].age = age;
        emit PersonAdded(user, name, age);
    }

    function get(address user) public view returns(string memory, uint8) {
        return (userIds[user].name, userIds[user].age); 
    }

}