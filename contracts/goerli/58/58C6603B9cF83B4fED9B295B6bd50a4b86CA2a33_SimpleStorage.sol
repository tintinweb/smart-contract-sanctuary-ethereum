/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    constructor() {}

    function store(uint256 newFavoriteNumber) public {
        uint256 oldNumber = favoriteNumber;
        favoriteNumber = newFavoriteNumber;
        emit storedNumber(
            oldNumber,
            newFavoriteNumber,
            newFavoriteNumber + oldNumber,
            msg.sender
        );
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}