/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
  // This gets initialized to zero
  // public variables implicitly get assigned a function that returns its value
  // The default visibility is internal
  // This variable is in the global scope
  uint256 favoriteNumber;

  mapping(string => uint256) public nameToFavoriteNumber;

  struct People {
    uint256 favoriteNumber;
    string name;
  }

  People[] public people;

  function store(uint256 _favoriteNumber) public virtual {
    favoriteNumber = _favoriteNumber;
  }

  // view and pure functions, when called alone, don't spend gas
  // view and pure functions disallow modification of state
  // pure functions additionally disallow reading from the blockchain state
  // if a gas consuming function calls a view or pure function then the view or pure function will cost gas
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138