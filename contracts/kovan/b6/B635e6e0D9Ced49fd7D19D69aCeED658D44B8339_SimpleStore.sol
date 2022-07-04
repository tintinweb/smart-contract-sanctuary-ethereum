//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStore {
    uint256 public favouriteNumber;
    event StoredNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );

    function store(uint256 newFavoriteNumber) public{
          
          emit StoredNumber(
            favouriteNumber,
            newFavoriteNumber,
            favouriteNumber + newFavoriteNumber,
            msg.sender
          );
        favouriteNumber = newFavoriteNumber;
    }
}