// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public favoriteNumber;

    // We want some things to get up to date when changes happen, so we need an event
    // Typically we emit after we make an update

    event storedNumber (
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );


    function store(uint256 newFavoriteNumber) public{
        emit storedNumber(
            favoriteNumber, 
            newFavoriteNumber,
            favoriteNumber + newFavoriteNumber,
            msg.sender
        );
        favoriteNumber = newFavoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }
}