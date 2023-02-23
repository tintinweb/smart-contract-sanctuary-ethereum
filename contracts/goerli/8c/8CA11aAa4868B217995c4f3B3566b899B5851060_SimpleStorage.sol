/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
  uint256 public favoriteNumber;
  mapping(string => uint256) public nameToFavoriteNumber;

  // uint256[] public favoriteNumber
  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view, pure functions don't consume gas
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}