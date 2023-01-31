// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
  uint256 public favoriteNumber;
  event storedNumber(
    uint256 indexed oldNumber,
    uint256 indexed newNumber,
    uint256 addedNumber,
    address sender
  );

  function store(uint256 _favoriteNumber) public {
    emit storedNumber(
        favoriteNumber,
        _favoriteNumber,
        _favoriteNumber + favoriteNumber,
        msg.sender
    );
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
      return favoriteNumber;
  }

}