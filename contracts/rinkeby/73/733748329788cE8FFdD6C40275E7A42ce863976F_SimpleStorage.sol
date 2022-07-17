// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// freeCodeCamp full stack turtorial

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view & pure functions are not readable on blockchain(no Gas feees)
    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata, memory,stroage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}