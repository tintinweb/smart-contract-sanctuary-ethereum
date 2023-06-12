// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 private favouriteNumber;
    Person[] public people;
    mapping(string => uint) public nameToFavouriteNumber;

    struct Person {
        string name;
        uint256 favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPeople(string memory _name, uint256 _favouriteNumber) public {
        people.push(Person({name: _name, favouriteNumber: _favouriteNumber}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}