/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleStorage {
    // assign integer
    uint256 public favoriteNumber;

    // define structure based on C language definition
    struct People {
        string name;
        uint256 number;
    }

    // assign struct
    People[] public people;

    // assign dictionary
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 number) public {
        favoriteNumber = number;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory name, uint256 number) public {
        people.push(People(name, number));
        nameToFavoriteNumber[name] = number;
    }
}