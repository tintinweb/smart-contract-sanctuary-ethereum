// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public person;
    mapping(uint256 => string) public nameToNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        person.push(People({favoriteNumber : _favoriteNumber, name : _name}));
        nameToNumber[_favoriteNumber] = _name;
    }
}