// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint public favoriteNumber;
    event storedNumber(
        uint indexed oldNumber,
        uint indexed newNumber,
        uint addedNumber,
        address sender
    );

    function store(uint _favoriteNumber) external {
        favoriteNumber = _favoriteNumber;
        emit storedNumber(
            favoriteNumber,
            _favoriteNumber,
            favoriteNumber + _favoriteNumber,
            msg.sender
        );
    }
}