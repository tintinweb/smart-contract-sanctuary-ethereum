/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        string name;
        uint id;
    }
    mapping(uint256 => string) public idToName;
    People[] public peopleList;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint256 _id) public {
        peopleList.push(People(_name, _id));
        idToName[_id] = _name;
    }
}