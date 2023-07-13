// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // Type, visibility, name is the typical way to intialize types
    uint256 favoriteNumber = 8;
    Person[] public people;
    mapping(string => uint256) public userToFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
        uint256 age;
    }

    function setFavoriteNumber(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    // _name is a string. A stirng is an array of bytes, so it needs to be stored in "memory". arrays, structs, and
    // mappings all need to be stored somewhere in storage.
    function addPerson(
        uint256 _favoriteNumber,
        string memory _name,
        uint256 _age
    ) public {
        people.push(Person(_favoriteNumber, _name, _age));
        userToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPerson(
        uint256 _personIndex
    ) public view returns (Person memory) {
        return people[_personIndex];
    }
}