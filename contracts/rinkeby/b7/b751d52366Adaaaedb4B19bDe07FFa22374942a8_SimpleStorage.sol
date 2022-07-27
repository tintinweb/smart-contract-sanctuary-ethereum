// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct Person {
        uint256 favouriteNumber;
        string name;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    uint256 favouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(Person({favouriteNumber: _favouriteNumber, name: _name}));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}