/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7; // Hello world

contract SimpleStorage {
  uint256 favNum;

  struct People {
    uint256 favNum;
    string name;
  }

  People[] public people;

  mapping(string => uint256) public nameToFavNum;

  function addPerson(string calldata _name, uint256 _favNum) public {
    people.push(People(_favNum, _name));
    nameToFavNum[_name] = _favNum;
  }

  function store(uint256 _favNum) public virtual {
    favNum = _favNum;
  }

  function retrieve() public view returns (uint256) {
    return favNum;
  }
}