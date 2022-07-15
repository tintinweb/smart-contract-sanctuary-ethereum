/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint favoriteNumner;

    struct people {
        string name;
        uint favNum;
    }
    people[] public peopleArray;
    mapping(string => uint) peopleToValue;

    function store(uint val) public {
        favoriteNumner = val;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumner;
    }

    function addPerson(string memory name, uint favNum) public {
        peopleArray.push(people(name, favNum));
        peopleToValue[name] = favNum;
    }
}