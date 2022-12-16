/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract LuckyNumber{

    struct user{
        uint number;
    }

    mapping (address => user) public users;

    function store(uint num) public{
        users[msg.sender].number = num;
    }

    function retrieve() public view returns (uint){
        return users[msg.sender].number;
    }
}