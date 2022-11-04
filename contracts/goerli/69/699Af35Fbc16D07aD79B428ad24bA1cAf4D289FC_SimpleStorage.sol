/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//EVM, Etherium Virtual Machine
contract SimpleStorage {
  //When you declare with no value it is
  //initiazled to 0
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

  //view, pure
  function retrieve() public view returns (uint256) {
    return favoriteNumber;
  }

  //calldata, memory, storage
  function addPerson(string memory _name, uint256 _favoriteNumber) public {
    people.push(People(_favoriteNumber, _name));
    nameToFavoriteNumber[_name] = _favoriteNumber;
  }
}