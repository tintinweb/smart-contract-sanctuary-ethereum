/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // Declares the version of Solidity being used

contract SimpleStorage {
    // Initialized as 0
    uint256 favoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    Person[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        Person memory newPerson = Person({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
    }
}