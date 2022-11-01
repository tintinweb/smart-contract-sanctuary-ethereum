/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PersonInfo {

    struct Person {
        string name;
        uint256 age;
        string nationality;
        address public_address;
    }

    Person person;

    constructor(){
        person.public_address = msg.sender;
    }

    function setAge(uint256 age) public {
        require(msg.sender == person.public_address, "Only owner can modify contract!");
        person.age = age;
    }

    function setName(string memory name) public {
        require(msg.sender == person.public_address, "Only owner can modify contract!");

        person.name = name;
    }

    function setNationality(string memory nat) public {
        require(msg.sender == person.public_address, "Only owner can modify contract!");

        person.nationality = nat;
    }

    function getPerson() public view returns (Person memory){
        return person;
    }
}