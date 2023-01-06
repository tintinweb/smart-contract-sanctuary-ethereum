/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 secretNumber;
    Person[] private people;
    mapping(string => uint8) nameToAge;

    struct Person {
        string name;
        uint8 age;
    }

    function storeSecretNumber(uint256 _secretNumber) public virtual {
        secretNumber = _secretNumber;
    }

    function getSecretNumber() public view returns (uint256) {
        return secretNumber;
    }

    function getPerson(uint256 _index) public view returns (Person memory) {
        return people[_index];
    }

    function getPeople() public view returns (Person[] memory) {
        return people;
    }

    function getAgeByName(string memory _name) public view returns (uint8) {
        return nameToAge[_name];
    }

    function addPerson(
        string calldata _name,
        uint8 _age
    ) public returns (uint256) {
        people.push(Person({name: _name, age: _age}));
        nameToAge[_name] = _age;
        return people.length;
    }
}