// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;
    mapping(string => uint256) public nameToFavoritenumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    People[] public person;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        person.push(People(_name, _favoriteNumber));
        nameToFavoritenumber[_name] = _favoriteNumber;
    }
}