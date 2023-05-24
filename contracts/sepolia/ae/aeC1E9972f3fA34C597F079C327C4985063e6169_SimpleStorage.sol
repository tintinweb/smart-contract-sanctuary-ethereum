/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    // boolean, uint, int, address, bytes, e.g. int256 favoriteInt = -5;

    // this gets initialized to 0; seen as a view function
    uint256 favoriteNumber; 

    // mapping is like a dictionary with key and value in js
    mapping(string => uint256) public nameToFavoriteNumber;

    // like ts interface
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // Dynamic array of people objects that stores all the people we create
    // we can give it a size by entering a number in the brackets
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view, pure cost no gas; read-only; no modification of state
    function retrieve () public view returns (uint256) {
        return favoriteNumber;
    }

    // adds a new person to the people[] array
    function addPerson (string memory _name, uint256 _favoriteNumber) public{
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
  
}