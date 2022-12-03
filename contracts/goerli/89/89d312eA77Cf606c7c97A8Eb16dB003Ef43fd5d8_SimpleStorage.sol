// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 private favourtieNumber;
    struct Person {
        uint256 favouriteNumber;
        string name;
    }
    Person[] public person;
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        favourtieNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favourtieNumber;
    }

    function addPerson(uint256 _favouriteNumber, string memory _name) public {
        person.push(Person(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}