/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // This is the version number of solidity

contract SimpleStorage {
    // this gets initiatlized to zero!
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    // Use underscores for parameters
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // View, pure keywords do not spend gas unless it is called
    // buy a function that costs gas
    //Only spend gas when changing state
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata (temp, cant be modified), memory (temp), storage
    function addPerson(string calldata _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}