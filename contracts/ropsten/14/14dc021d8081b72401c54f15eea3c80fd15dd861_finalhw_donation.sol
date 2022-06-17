/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract finalhw_donation{
     struct Person {
        uint id;
        string name;
        uint256 amount;
        address sender_address;
    }

    uint256 id = 0;
    mapping(uint => Person) public people;

    function addPerson(string memory name) public payable {
        id += 1;
        people[id] = Person(id, name, msg.value, msg.sender);
    }



}