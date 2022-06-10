/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
  // boolean, uint, int, address, bytes : basic variable types
  // bool t = true;
  // uint256 n = 101;
  // string s = "something";
  // int32 l = -2;
  // address myAddress = 0x3DC27fad761B4B32fd63De47f17AFF81bE83A4D1;
  // bytes32 b = "20happy";

  uint256 public favoriteNumber; // default intialised to 0
  // People public person = People({ favoriteNumber: 10, name: 'Swaps'});

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;
  mapping(string => uint256) public nameToFavoriteNumber;

  function store(uint256 _fav) public virtual {
    favoriteNumber = _fav;
  }

  // view/pure function
  function retreive() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _fav) public {
    people.push(People({favoriteNumber: _fav, name: _name}));
    nameToFavoriteNumber[_name] = _fav;
  }

  function personCount() public view returns (uint256) {
    return people.length;
  }
}