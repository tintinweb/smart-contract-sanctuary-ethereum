// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favouriteNumber;
    struct Person {
        string name;
        uint256 favouriteNumber;
    }
    Person[] public person;
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        person.push(Person(_name, _favouriteNumber));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}