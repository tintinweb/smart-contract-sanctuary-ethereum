// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;

    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newNumber) public {
        emit storedNumber(
            favoriteNumber,
            newNumber,
            (favoriteNumber + newNumber),
            msg.sender
        );
        favoriteNumber = newNumber;
    }
}