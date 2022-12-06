/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favouriteNumber;
    Person[] public persons;
    mapping(string => uint256) public favouriteNumberByName;

    struct Person {
        uint256 favouriteNumber;
        string name;
    }

    function storeFavouriteNumber(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieveFavouriteNumber() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(uint256 _favouriteNumber, string calldata _name) public {
        persons.push(Person(_favouriteNumber, _name));
        favouriteNumberByName[_name] = _favouriteNumber;
    }
}