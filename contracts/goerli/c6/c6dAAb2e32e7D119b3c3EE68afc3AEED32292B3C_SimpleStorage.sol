// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newFavouriteNumber) public {
        emit storedNumber(
            favoriteNumber,
            newFavouriteNumber,
            favoriteNumber + newFavouriteNumber,
            msg.sender
        );
        favoriteNumber = newFavouriteNumber;
    }
}