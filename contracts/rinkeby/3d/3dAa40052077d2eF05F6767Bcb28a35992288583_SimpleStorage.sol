// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15; // solidity 0.8.15

contract SimpleStorage {
  // boolean, unit, init, address, bytes
  uint256 favoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }
  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  // calldata the variable can't be modify
  // memory: the value is stored in memory temporarily, and is lost when the contract ends.
  // storage: the value is stored in the contract's event outside function.
  // string actually is array of bytes, string is seceretly an array.

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}