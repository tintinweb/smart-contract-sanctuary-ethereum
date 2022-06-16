/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public favNumber;

    struct Person {
        uint256 favNumber;
        string name;
    }

    Person[] public people;
    mapping(string => uint256) public personToFavNumber;

    function store(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function getFavNumber() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(uint256 _favNum, string memory _name) public {
        people.push(Person(_favNum, _name));
        personToFavNumber[_name] = _favNum;
    }
}