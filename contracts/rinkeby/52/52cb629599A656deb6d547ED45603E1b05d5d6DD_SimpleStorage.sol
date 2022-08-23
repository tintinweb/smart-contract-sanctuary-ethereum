// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
  uint256 public favoriteNumber;

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    string name;
    uint256 favoriteNumber;
  }

  People[] public person;

  function store(uint256 _favoriteNumber) external {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() external view returns (uint256) {
    return favoriteNumber;
  }

  function addPeople(string memory _name, uint256 _favoriteNumber) external {
    person.push(People(_name, _favoriteNumber));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}