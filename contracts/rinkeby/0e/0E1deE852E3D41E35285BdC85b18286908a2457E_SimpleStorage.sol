// SPDX-License-Identifier: MIT

pragma solidity 0.8.8; // version == 0.8.8

// pragma solidity ^0.8.8; // -> version >= 0.8.8
// pragma solidity >= 0.8.0 <= 0.9.0; // -> between 0.8.0 and 0.9.0

contract SimpleStorage {
  uint256 favoriteNumber;
  // string myName = "VH";
  // bool public myBool;
  // int256 public myInt;
  struct Person {
    uint256 favNumber;
    string name;
  }

  // Dynamic array
  Person[] public person;
  // Person public person1 = Person(7, "VH");

  // mapping
  mapping(string => uint256) public personMap;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // Pushes Person datatype to person array
  function addPerson(uint256 _favNumber, string memory _name) public {
    person.push(Person(_favNumber, _name));
    personMap[_name] = _favNumber;
  }
}