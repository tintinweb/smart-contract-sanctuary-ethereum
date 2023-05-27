/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// Hi, I am comment line
// SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.7;

//contract
contract SimpleStorage {
  //global variables
  uint256 favoriteNumber;

  //structs
  struct People {
    string name;
    uint256 number;
  }

  //array

  People[] public people;

  //mapping
  mapping(string => uint256) public nameToFavoriteNumber;

  //functions
  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  function addPeople(string memory _name, uint256 _number) public {
    people.push(People(_name, _number));
    nameToFavoriteNumber[_name] = _number;
  }

  function retrive() public view returns (uint256) {
    return favoriteNumber;
  }
}