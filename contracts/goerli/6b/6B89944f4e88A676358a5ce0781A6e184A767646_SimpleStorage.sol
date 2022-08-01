// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        bytes32 name;
        uint256 favoriteNumber;
    }

    People[] public people;

    mapping(bytes32 => uint256) nameToFavoriteNumber;

    function store(uint256 favNumber) public {
        favoriteNumber = favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(bytes32 name, uint256 favNumber) public {
        people.push(People(name, favNumber));
        nameToFavoriteNumber[name] = favNumber;
    }
}