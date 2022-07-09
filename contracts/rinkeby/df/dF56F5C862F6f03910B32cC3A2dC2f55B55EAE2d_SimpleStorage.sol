// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // most common 0.8.12 but 0.8.7 is considered stable

contract SimpleStorage {
    uint256 favoriteNumber;

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        // OR people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}