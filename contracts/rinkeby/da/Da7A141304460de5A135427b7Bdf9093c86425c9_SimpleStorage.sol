/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; 

contract SimpleStorage {

    uint256 favoriteNumber;

    //uint256[] public favoriteNmberList
    People[] public people;
    //mapping we want to use the name and get a person favorite number
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //functionthat add people to our people array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}