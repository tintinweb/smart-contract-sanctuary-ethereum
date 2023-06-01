// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract SimpleStorage {
    uint256 public favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPeople(uint256 _favoriteNumber, string memory _name) public {
        // Adding to Struct
        People memory newPerson = People({
            favoriteNumber: _favoriteNumber,
            name: _name
        });
        people.push(newPerson);
        // Add to mappings
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function peopleAdded() public view returns (uint256) {
        return people.length;
    }
}