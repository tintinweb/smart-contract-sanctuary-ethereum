/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract SimpleStorage {
  uint256 private favorateNumber;

  struct People {
    uint256 favorateNumber;
    string name;
  }

  People[] public people;
  mapping(string => uint256) public nameToFavorateNumber;

  function store(uint256 _favorateNumber) public {
    favorateNumber = _favorateNumber;
  }

  function retrieve() public view returns (uint256) {
    return favorateNumber;
  }

  function addPerson(string memory _name, uint256 _favorateNumber) public {
    people.push(People(_favorateNumber, _name));
    nameToFavorateNumber[_name] = _favorateNumber;
  }
}