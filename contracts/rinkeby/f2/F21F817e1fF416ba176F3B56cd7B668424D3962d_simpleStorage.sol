/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

contract simpleStorage {
  uint256 number;

  struct addPeople {
    string name;
    uint256 number;
  }

  addPeople[] public peopleArray;
  mapping(string => uint256) nameToNumber;

  function store(uint256 _number) public {
    number = _number;
  }

  function retrieve() public view returns (uint256) {
    return number;
  }

  function addPlayer(string memory _name, uint256 _number) public {
    peopleArray.push(addPeople(_name, _number));
    nameToNumber[_name] = _number;
  }
}