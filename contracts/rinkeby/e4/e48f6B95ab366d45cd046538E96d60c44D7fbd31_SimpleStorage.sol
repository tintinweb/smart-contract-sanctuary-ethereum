// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // ^ means 0.8.7 or above is ok

// >= 0.8.7 < 0.9.0 -> between is ok

// Types -> boolean(bool), uint, int, adress, bytes, string, address
// bool hasFavoriteNumber = true;
// uint256 favoriteNumber = 7;
// string FavoriteNumberInText = "Seven";
// int256 favoriteInt = -7;
// address myAdress = 0xbb6ba66A466Ef9f31cC44C8A0D9b5c84c49A4ba8;
// bytes32 favoriteBytes = "cat";

// Function Visibility Specifier:
// public : visible externally and internally (creates a getter function for storage/ state variables(
// private : only visible in the current contract
// external . only visible externally (only for functions - i.e can be only message-called(via this func)
// internal : only visible internally

contract SimpleStorage {

    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual { // virtual for OOP
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256){
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
} // address of the Smart Contract: 0xd9145CCE52D386f254917e481eB44e9943F39138