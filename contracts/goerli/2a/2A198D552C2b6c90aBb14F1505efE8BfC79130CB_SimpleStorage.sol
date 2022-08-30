/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favouriteNumber;

    struct Person {
        uint256 favouriteNumber;
        string name;
    }

    Person[] public people;

    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(uint256 _favouriteNumber, string memory _name) public {
        people.push(Person(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }
}