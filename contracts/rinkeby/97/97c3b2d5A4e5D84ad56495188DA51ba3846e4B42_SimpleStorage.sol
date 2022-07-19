// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;
    People[] public people;

    struct People {
        string name;
        uint256 favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_name, _favoriteNumber));
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}