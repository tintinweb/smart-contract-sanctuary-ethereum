/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;
 
contract PersonInformation {
 
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
        require(msg.sender == person.public_address, "Only contract owner can modify this");
 
        person.age = age;
    }
 
    function setName(string memory name) public {
        require(msg.sender == person.public_address, "Only contract owner can modify this");
 
        person.name = name;
    }
 
    function setNationality(string memory nat) public {
        require(msg.sender == person.public_address, "Only contract owner can modify this");
 
        person.nationality = nat;
    }
 
    function getPerson() public view returns (Person memory){
        require(msg.sender == person.public_address, "Only contract owner can modify this");
 
        return person;
    }
}