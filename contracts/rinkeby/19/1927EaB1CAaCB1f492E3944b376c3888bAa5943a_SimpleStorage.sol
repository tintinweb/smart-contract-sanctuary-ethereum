/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;
    mapping(string => uint256) public nametoFavoriteNumber;

    // struct refers to customed object type
    struct People {
        string name;
        uint256 favoritNumber;
    }

    // Syntax of variable initiation: [object type] [visibility] [variable name]
    People[] public people;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        // The `People` object is:   People{}
        // The `People` instance is: People()
        people.push(People(_name, _favoriteNumber));
        nametoFavoriteNumber[_name] = _favoriteNumber;
    }
}