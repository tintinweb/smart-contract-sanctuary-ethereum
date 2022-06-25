/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256 favNumber;

  struct People {
    uint256 favNumber;
    string name;
  }
  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameTofavNumber;

  function store(uint256 _favNumber) public {
    favNumber = _favNumber;
  }

  function retrieve() public view returns (uint256) {
    return favNumber;
  }

  function addPerson(string memory _name, uint256 _favNumber) public {
    people.push(People(_favNumber, _name));
    nameTofavNumber[_name] = _favNumber;
  }
}