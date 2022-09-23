/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
  uint256 public favoriteNumber;

  struct People {
    string name;
    uint256 favoriteNumber;
  }
  People[] public people;

  function addPeople(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_name, _favoriteNumber));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = add(_favoriteNumber, 3);
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function add(uint256 a, uint256 b) public pure returns (uint256) {
    return a + b;
  }
}