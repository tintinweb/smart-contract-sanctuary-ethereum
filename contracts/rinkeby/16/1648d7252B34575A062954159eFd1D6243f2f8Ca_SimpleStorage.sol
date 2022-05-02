/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// File: SimpleStorage.sol

contract SimpleStorage {
    // Contents of our contract simple storage.

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Array of people. (Dynamic Array)
    People[] public people;
    // Type mapping of string mapped to uint256
    mapping(string => uint256) public nameToFavoriteNumber;

    // Instatiation of the struct: Person variable
    People public person = People({favoriteNumber: 2, name: "Patrick"});

    function store(uint256 _favoriteNumber) public returns (uint256) {
        favoriteNumber = _favoriteNumber;
        return favoriteNumber;
    }

    // // Pure - do some type of math
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Don't need to describe the dict key pair, just use indexes to assume
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // Add to mapping
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}