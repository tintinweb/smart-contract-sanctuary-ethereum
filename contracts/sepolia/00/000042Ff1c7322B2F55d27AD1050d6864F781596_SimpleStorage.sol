// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // This global variable gets initialize to zero
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList; (an Array)
    // 0: 7, Tameka | 1: 21, Andre

    People[] public people;

    // A mapping is a data structure where a key is "mapped" to a single value - think of it as a dictionary
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // View function - ability to READ contract state only but disallows any modifications to the blockchain
    // Pure function - no ability to READ contract state & disallows any modifications to the blockchain
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // Calldata - temporary variables that CANNOT be modified
    // Memory - temporary variables that CAN be modified
    // Storage - permanent variables that CAN be modified
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}