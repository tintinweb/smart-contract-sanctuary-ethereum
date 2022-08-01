/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract SimpleStorage {
  uint256 favoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }
  People[] public people;

  mapping(string => uint256) nameToFavouriteNumber;

  function store(uint256 _favouriteNumber) public {
    favoriteNumber = _favouriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favouriteNumber) public {
    people.push(People(_favouriteNumber, _name));
    nameToFavouriteNumber[_name] = _favouriteNumber;
  }
}