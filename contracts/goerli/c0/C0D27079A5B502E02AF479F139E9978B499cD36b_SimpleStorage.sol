//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    //You can define your own type by creating a struct: they are useful for grouping related data
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public anArray
    People[] public people;

    //mapping is a reference type as array and struct. ie is like dictionary and hash table in other languages
    // syntax: mapping(_KeyType => _ValueType)
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}