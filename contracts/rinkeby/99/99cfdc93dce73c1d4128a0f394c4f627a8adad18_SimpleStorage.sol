/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8; // 0.8.7 is considered a more stable version

contract SimpleStorage {
    uint256 favoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    function addPerson(uint256 _favoriteNumber, string memory _name) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() view public returns(uint256) {
        return favoriteNumber;
    }
}