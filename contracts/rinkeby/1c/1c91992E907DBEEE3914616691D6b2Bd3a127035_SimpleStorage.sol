/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

//  Always want to include a license identifier
//  SPDX-License-Identifier:  MIT

pragma solidity ^0.8.7;

// 0.8.12 ^ means anything from 0.8.7 and above will be acceptable
// can also do pragma solidity >=0.8.7 <0.9.0; means anything between 0.8.7 and 0.8.whatever
// ; indicates the end of an line

contract SimpleStorage {
  //since there isn't a value assigned, it gets initialized to 0
  uint256 favoriteNumber;

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  // brackets indicate an array
  People[] public people;

  // the _ indicates that this is a different variable/parameter than the other one
  function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}