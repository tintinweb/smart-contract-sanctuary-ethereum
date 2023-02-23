/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct People {
    uint256 favoriteNumber;
    string name;
}

contract SimpleStorage {
    uint256 favoriteNumber;
    People[] peoples;
    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _FavoriteNumber) public {
        favoriteNumber = _FavoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        peoples.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}