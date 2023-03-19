/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Hello_World {
    string public greetingPrefix = "Hello World!";
    string public petName;
    string public age;
    string public owner;

    constructor(){
        petName = "kitty";
        age = "2";
        owner = "john doe";
    }

    function setPetName(string memory newPetName) public{
        petName = newPetName;
    }

    function setAge(string memory newAge) public {
        age = newAge;
    }

    function setOwnder(string memory newOwner) public{
        owner = newOwner;
    }

    function greet() public view returns (string memory){
        return string(abi.encodePacked(greetingPrefix,"My name is ", petName, " I am ", age, " yrs old and my owner's name is ",owner));
    }
}