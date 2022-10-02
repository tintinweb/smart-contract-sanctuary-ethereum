// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
  // bool hasFavoriteNumber = true;
  // uint256 favoriteNumber = 123;
  // string favoriteNumberInText = "Five";
  // int256 favoriteInt = -5;
  // address myAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
  // bytes32 favoriteBytes = "cat"; // auto-converts to bytes type
  uint256 favoriteNumber; // defaults to 0

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view, pure
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}