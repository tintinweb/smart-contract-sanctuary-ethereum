// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 favoriteNumber;

    struct Products {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    Products[] public people;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addProduct(string memory _name, uint256 _favoriteNumber) public {
        people.push(Products(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}