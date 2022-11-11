/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favouriteNumber;

    struct Person {
        string name;
        uint256 favouriteNumber;
    }

    Person[] public people;

    mapping(string => uint256) public nameToNumber;

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(Person(_name, _favouriteNumber));
        nameToNumber[_name] = _favouriteNumber;
    }
}