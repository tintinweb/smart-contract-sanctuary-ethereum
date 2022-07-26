/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

//////////////////////////////////////////
/// Lesson 5: Ethers.js Simple Storage ///
//////////////////////////////////////////

pragma solidity ^0.8.15.0;

contract SimpleStorage {
    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    uint256 internal favoriteNumber;
    Person[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(Person({name : _name, favoriteNumber : _favoriteNumber}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}