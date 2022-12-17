// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SimpleStorage {
    uint favoriteNumber; // Initialized to zero and everyone can access

    function Store(uint _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure functions doesn't spend gas fee
    function Retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    mapping(string => uint) public nameToFavoriteNumber; // name to favnum mapping

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people; // Create Array

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));

        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}