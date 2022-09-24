/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // Gets initialized to 0
    uint256 public favoriteNumber;

    // Good to create 1
    // People public person = People({favoriteNumber: 2, name: 'Patrick'});
    // BUT better to use an array for several people
    People[] public people;
    // We can limit the size of the array with People[3]
    // uint256[] public favoriteNumberList;

    // A dictionary to map some name to their favorite number
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // "virtual" allows this function to be overrided in a inherited contract
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // This gets created quietly
    // A view function lets you only read from the blockchain (0 gas)
    // Costs gas only if called from a costly function
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata & memory : only exists temporarily
    // e.g. favoriteNumber is a storage variable
    // It already knows a uint256 exists in memory (but doesn't know for string)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // Get the name associated to their fav number in the mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}