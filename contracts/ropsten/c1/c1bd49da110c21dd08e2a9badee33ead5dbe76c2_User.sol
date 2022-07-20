/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract User {
    event Register(address indexed addr, string indexed name, uint256 indexed age);
    struct user {
        address addr;
        string name;
        uint256 age;
    }
    mapping(address => user) public users;

    function set(address addr, string memory name, uint256 age) private {
        users[addr] = user(addr, name, age);
    }

    function register(address addr, string memory name, uint256 age) public {
        require(users[addr].addr == address(0), "address is exists");
        set(addr, name, age);
        emit Register(addr, name, age);
    }
}