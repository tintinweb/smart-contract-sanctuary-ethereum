// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;
    mapping(address => uint256) public addressToFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }

    function storeNumber(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
    }

    function retreive() public view returns (uint256) {
        return favoriteNumber;
    }
}