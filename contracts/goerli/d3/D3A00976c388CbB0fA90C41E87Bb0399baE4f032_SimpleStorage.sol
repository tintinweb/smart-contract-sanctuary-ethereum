// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people; // Dynamic array... Array of People object declared as public and store in the variable people

    // Here we have a dictionary where a given is going to mapped to a specific number
    mapping(string => uint256) public nameToFavoriteNumber;

    // takes in some parameter as input and sets favoriteNumber to the input.
    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // This is an explicitly defined getter function that return favoriteNumber
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}