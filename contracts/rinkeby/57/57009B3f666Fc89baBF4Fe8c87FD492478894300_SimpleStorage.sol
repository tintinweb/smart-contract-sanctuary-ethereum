/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint favoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    People[] public people;

    mapping(uint256 => string) public nameToFavoriteNumber;

    function store(uint _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_favoriteNumber] = _name;
    }
}