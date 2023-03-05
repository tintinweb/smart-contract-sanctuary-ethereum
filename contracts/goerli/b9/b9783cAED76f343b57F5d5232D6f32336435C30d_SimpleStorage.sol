// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    uint256 public previousFavoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newFavoriteNumber) public {
        emit storedNumber(
            favoriteNumber,
            newFavoriteNumber,
            favoriteNumber + newFavoriteNumber,
            msg.sender
        );
        previousFavoriteNumber = favoriteNumber;

        favoriteNumber = newFavoriteNumber;
    }

    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    function getPreviousFavoriteNumber() public view returns (uint256) {
        return previousFavoriteNumber;
    }
}