/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorage {

    // Initialized as 0 by default
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    // View, Pure - do not have to pay to read state from chain
    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People({favoriteNumber: _favoriteNumber, name: _name}));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}