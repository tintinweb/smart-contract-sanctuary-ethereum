/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Structs {
    struct User {
        string name;
        uint8 age;
    }

    mapping(address => User) public users;

    function register(string memory name, uint8 age) external returns(bool){
        users[msg.sender] = User(name, age);
        return true;
    }
}