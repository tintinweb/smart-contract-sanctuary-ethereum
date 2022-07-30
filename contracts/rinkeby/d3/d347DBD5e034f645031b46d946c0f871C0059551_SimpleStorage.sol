//*******************************//
// SPDX-License-Identifier: MIT
// Lesson 1
// This lesson introduces the basics of Solidity syntaxis.
// We also created a simple contract that can store and return a favorite number according to the person.
//*******************************//
// Basic Solidity
// Deploying to a test network
//*******************************//

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    // This is a comment!
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
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