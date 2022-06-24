// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256 favoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }
  // uint256[] public anArray;
  //This is a dynamic array, can take upto any number
  People[] public people;

  mapping(string => uint256) public nameToFavoriteNumber;

  //Virtue makes it possible to be overriden
  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  //View/pure only cost gas when called inside a function that cost gas otherwise it doesnt cost a gas.
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}