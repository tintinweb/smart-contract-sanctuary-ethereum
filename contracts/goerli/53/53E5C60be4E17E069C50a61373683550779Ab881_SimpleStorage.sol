/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint favoriteNumber;
    mapping(string => uint) public nameToFavoriteNumber;

    Person[] public persons;

    struct Person {
        uint favoriteNumber;
        string name;
    }

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    function addPerson(string calldata _name, uint _favoriteNumber) public {
        nameToFavoriteNumber[_name] = _favoriteNumber;
        persons.push(Person(_favoriteNumber, _name));
    }
}