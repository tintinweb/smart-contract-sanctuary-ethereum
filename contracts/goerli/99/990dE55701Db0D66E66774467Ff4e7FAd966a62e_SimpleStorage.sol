// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256 favouriteNumber;

  struct People {
    uint256 favouriteNumber;
    string name;
  }
  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favouriteNumber) public {
    favouriteNumber = _favouriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favouriteNumber;
  }

  function addPerson(string memory _name, uint256 _favouriteNumber) public {
    people.push(People(_favouriteNumber, _name));
    nameToFavoriteNumber[_name] = _favouriteNumber;
  }
}