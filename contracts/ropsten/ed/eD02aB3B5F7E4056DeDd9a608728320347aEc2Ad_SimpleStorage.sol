//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract SimpleStorage {
    uint256 public favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newfavoriteNumber) public {
        emit storedNumber(
            favoriteNumber,
            newfavoriteNumber,
            favoriteNumber + newfavoriteNumber,
            msg.sender
        );
        favoriteNumber = newfavoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}