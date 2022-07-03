/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // The version we are gonna use.

contract SimpleStorage {
    // boolean, uint, int, address, bytes - these are the solidity types (used to define variables)

    
    uint256  favoriteNumber; // without giving it any value, it gets set to 0
    mapping(string => uint256) public nameToFavoriteNumber;  // Mapping helps you assign certain things to find them later, like a string to a uint256, like a dictionary

    struct People {     // This creates new type called People, similar to strings, int etc.
        uint256 favoriteNumber;
        string name;
    }

    People[] public people; // This creates a new array called People 


    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }
   
    
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }
    
    // Section about storing data
    // calldata, memory, storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

}

// 0xd9145CCE52D386f254917e481eB44e9943F39138