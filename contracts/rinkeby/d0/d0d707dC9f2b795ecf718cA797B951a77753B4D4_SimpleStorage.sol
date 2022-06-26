// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    // this is a storage var
    uint256 favoriteNumber;

    // mappings are like dicts
    mapping(string => uint256) public nameToFavoriteNumber;

    // this is a dynamic array
    People[] public people;

    // struct allows you to create a new type
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // calldata are temporary vars that cannot be modified, memory are temporary vars the can be modified
    // storage are permanent vars that can be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //  view functions only allow you to read state. View disallow any modifiaction of state
    // pure functions disallows modification of state and reading state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}