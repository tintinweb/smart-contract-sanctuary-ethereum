// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNubmer;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newFavoriteNumber) public {
        emit storedNumber(
            favoriteNubmer,
            newFavoriteNumber,
            favoriteNubmer + newFavoriteNumber,
            msg.sender
        );
        favoriteNubmer = newFavoriteNumber;
    }
}