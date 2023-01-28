/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
  uint256 favNum;

  struct People {
    string name;
    uint256 favNum;
  }

  mapping(string => uint256) public nameToFav;
  People[] public people;

  function store(uint256 _favNum) public {
    favNum = _favNum;
  }

  function retrieve() public view returns (uint256) {
    return favNum;
  }

  function addPerson(string memory _name, uint256 _favNum) public {
    people.push(People(_name, _favNum));
  }
}