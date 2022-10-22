/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleStorage {
    uint favoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(string=>uint) public nameToFavoriteNumber;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}