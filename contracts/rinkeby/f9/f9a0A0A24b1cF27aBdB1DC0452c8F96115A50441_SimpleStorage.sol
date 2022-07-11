// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}