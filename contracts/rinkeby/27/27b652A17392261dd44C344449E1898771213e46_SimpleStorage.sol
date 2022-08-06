/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//boolean uint int address bytes
contract SimpleStorage {
  uint256 public hasfavouirateno1;
  struct People {
    uint256 id;
    string name;
  }
  mapping(string => uint256) public nametonumber; //
  People[] public totalpeople;

  function addperson(string memory _name, uint256 _id) public {
    totalpeople.push(People({name: _name, id: _id}));
    nametonumber[_name] = _id;
  }

  function store(uint256 hasfav) public virtual {
    hasfavouirateno1 = hasfav * 2;
  }

  function retrive() public view returns (uint256) {
    return hasfavouirateno1;
  }

  function pure2() public pure returns (uint256) {
    return (2 + 2);
  }
}