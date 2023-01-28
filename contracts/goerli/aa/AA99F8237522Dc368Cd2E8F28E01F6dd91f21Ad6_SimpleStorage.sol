/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // ^ => any version of 0.8.7 and above

contract SimpleStorage {
    uint256 favoriteNumber; //Get initialized to 0

    // mapping to store the relationship between names and favorite numbers
    mapping(string => uint256) public nameToFavoriteNumber;

    // A struct to store information about people
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // An array to store multiple people's information
    People[] public people;

    // Store a favorite number
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // Retrieve the stored favorite number
    // view and pure don't need any gas, they don't modify the blockchain state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Add a person's name and favorite number
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}