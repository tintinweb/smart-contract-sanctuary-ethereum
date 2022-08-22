/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    People[] public people;

    mapping(string => uint256) public nameToFavourtieNumber;

    function store(uint256 _favouriteNumber) public virtual {
        favoriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavourtieNumber[_name] = _favouriteNumber;
    }
}