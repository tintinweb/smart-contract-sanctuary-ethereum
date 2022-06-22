/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    struct People {
        string name;
        uint256 age;
    }

    People[] public people;
    mapping(string => uint256) public myMapping;

    function addPerson(string memory fname, uint256 umr) public {
        people.push(People(fname, umr));
        myMapping[fname] = umr;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}