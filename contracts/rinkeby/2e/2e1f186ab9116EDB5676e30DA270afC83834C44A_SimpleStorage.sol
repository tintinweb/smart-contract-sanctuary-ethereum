// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favorateNumber;

    event storedNumber (
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newFavoriteNumber) public {
        emit storedNumber(
            favorateNumber,
            newFavoriteNumber,
            favorateNumber + newFavoriteNumber,
            msg.sender
        );
        favorateNumber = newFavoriteNumber;
    }
}