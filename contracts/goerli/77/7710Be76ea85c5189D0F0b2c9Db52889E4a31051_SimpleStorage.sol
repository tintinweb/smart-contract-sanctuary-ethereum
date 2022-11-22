/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    Person[] public people;
    mapping(string => Person) public peopleMap;

    function addPerson(string memory name, uint256 favoriteNumber)
        public
        virtual
    {
        Person memory person = Person(favoriteNumber, name);
        people.push(person);
        peopleMap[name] = person;
    }

    function getPerson(string memory name) public view returns (Person memory) {
        return peopleMap[name];
    }
}