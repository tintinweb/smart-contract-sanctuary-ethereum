/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
  //bool hasFavoriteNumber = true;
  uint256 favoriteNumber;
  //People public person = People({favoriteNumber:2, name: "Mirksen"});

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  //uint256[] public favoriteNumberList;
  People[] public people;

  /*
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0x4c423Ff2d41f2085Aa0F0CD02C714A6Cf057F1d0;
    bytes32 favoriteBytes = "cat";
    */

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
    //favoriteNumber = favoriteNumber + 1;
    retrieve();
  }

  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}