/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
  uint256 favoriteNumber;
  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  // "view" can read; "pure" can just calculate
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}