/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
  uint256 public favoriteNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    People memory person = People({
      favoriteNumber: _favoriteNumber,
      name: _name
    });
    people.push(person);
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}