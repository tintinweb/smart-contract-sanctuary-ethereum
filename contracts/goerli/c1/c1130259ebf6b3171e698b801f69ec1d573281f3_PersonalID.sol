/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract PersonalID {

    struct PersonID {
        string name;
        string middle_name;
        string surname;
        uint256 age;
        string citizenship;
        string nationality;
        address public_address;
    }

    PersonID personID;

    constructor(){
        personID.public_address = msg.sender;
    }

    function setName(string memory Name) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.name = Name;
    }

    function setMiddleName(string memory Middle_Name) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.middle_name = Middle_Name;
    }

    function setSurname(string memory Surname) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.surname = Surname;
    }

    function setAge(uint256 Age) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.age = Age;
    }

    function setCitizenship(string memory Citizenship) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.citizenship = Citizenship;
    }

    function setNationality(string memory Nationality) public {
        require(msg.sender == personID.public_address, "Only contract owner can modify this");
        personID.nationality = Nationality;
    }

    function getPersonID() public view returns (PersonID memory){
        return personID;
    }
}