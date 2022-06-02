// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Event {
    uint256 public favoriteNumber = 54;
    event storedNumber(
        uint256 indexed oldNum,
        uint256 indexed newNum,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 _favoriteNumber) public {
        uint256 addedNumber = favoriteNumber + _favoriteNumber;
        emit storedNumber(
            favoriteNumber,
            _favoriteNumber,
            addedNumber,
            msg.sender
        );
        favoriteNumber = _favoriteNumber;
    }
}