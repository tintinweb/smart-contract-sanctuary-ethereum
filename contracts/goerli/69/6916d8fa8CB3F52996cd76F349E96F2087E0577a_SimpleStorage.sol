/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 .0; // 0.8.12

contract SimpleStorage {
  // uint defualt : 256
  // bytes : byte[]
  // default initialized to zero.
  // default internal
  // default storage variable
  uint256 internal favoriteNumber;
  // People public person = People({favoriteNumber: 2, name: "Patrick"});

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view, pure disallow any modification. And pure only use the function parameter.
  // Cost only applies when called by a contract.
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  // calldata(temp & immutable), memory(temp & mutable), storage
  // string is called by reference, but uint is called by value.
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}