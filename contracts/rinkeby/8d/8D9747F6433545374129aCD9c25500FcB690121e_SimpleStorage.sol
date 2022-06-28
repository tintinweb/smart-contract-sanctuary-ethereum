// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
  uint256 public favoriteNumber;

  struct Person {
    uint256 number;
    string name;
  }

  Person[] public people;

  mapping(string => uint256) public nameToNumber;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function addPerson(uint256 _number, string memory _name) public {
    people.push(Person(_number, _name));
    nameToNumber[_name] = _number;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }
}