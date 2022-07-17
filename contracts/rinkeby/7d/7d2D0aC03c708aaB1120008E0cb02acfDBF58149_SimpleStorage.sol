// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract SimpleStorage {
  uint256 favoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  function store() public view returns (uint256) {
    return favoriteNumber;
  }

  function updateStore(uint256 _favouriteNumber) public {
    favoriteNumber = _favouriteNumber;
  }

  // function retrieve() public view returns (uint256) {
  //   return favoriteNumber;
  // }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}