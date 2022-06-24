// I'm a comment!
// SPDX-License-Identifier: MIT

// pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
        uint256 balance;
    }

    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(
        string memory _name,
        uint256 _favoriteNumber,
        uint256 _balance
    ) public {
        people.push(People(_favoriteNumber, _name, _balance));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function getPerson(uint256 index) public view returns (People memory) {
        return people[index];
    }
}