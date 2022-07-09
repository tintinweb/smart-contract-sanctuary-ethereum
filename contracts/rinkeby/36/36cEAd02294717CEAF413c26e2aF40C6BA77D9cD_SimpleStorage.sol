//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favouriteNumber;
    struct People {
        uint256 favoriteNumber;
        string name;
    }
    mapping(string => uint256) public nameToFavoriteNumber;
    People[] public people;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}