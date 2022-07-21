// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
  uint256 voteFor;

  struct People {
    uint256 voteFor;
    string name;
  }

  // uint256[] public anArray;
  People[] public people;

  mapping(string => uint256) public nameToVoteFor;

  function store(uint256 _fn) public {
    voteFor = _fn;
  }

  function retrieve() public view returns (uint256) {
    return voteFor;
  }

  function addPerson(string memory _name, uint256 _fn) public {
    people.push(People(_fn, _name));
    nameToVoteFor[_name] = _fn;
  }
}