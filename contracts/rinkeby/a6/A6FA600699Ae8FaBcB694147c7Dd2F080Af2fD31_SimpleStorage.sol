// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    mapping(string => uint256) peoples;

    People[] public people;

    function addPerson(string memory name, uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        people.push(People(name, _favoriteNumber));
        peoples[name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}