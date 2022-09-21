/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// Define the version of the solidity
// Put caret to any version in 8 then ^0.8.7
// To define a range >=0.8.7 <0.9.0
//

// All the code compiles down to EVM - etherium virtual machine
// Examples of EVM are Avalance Fantom, Polygon [EVM compatible]
//
contract SimpleStorage {
  // Data types
  // boolean, unit, int, address, bytes, string
  //
  bool hasFavNumber = false;
  uint256 favNumberUnit = 2345; // this can go till 256
  int256 favNumber = -463826;
  string name = "test name";
  address myAddress = 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF;
  bytes32 byteData = "cat"; // bytes32 is max

  // People public ram = People({ name: "Ram", age: 23 });

  // Struct
  struct People {
    string name;
    uint256 age;
  }

  // Dynamic array
  People[] public persons;

  // dictionary
  mapping(string => uint256) public nameToAgeMapping;

  // memory is needed for array struct or mapping types.
  function addPerson(string memory _name, uint256 _age) public {
    persons.push(People(_name, _age));
    nameToAgeMapping[_name] = _age;
  }

  // Not defining means this will be zero as this is unsigned int
  uint256 public someValue;

  function setValue(uint256 _someValue) public virtual {
    someValue = _someValue;
  }

  // view functions do not need gas.
  // gas is needed only when you are modifying the state of the contract.
  // If this function is called from the internal function then gas will be included.

  function getValue() public view returns (uint256) {
    return someValue;
  }
}

// There are 6 places where you can store the data
/*
01. stack 
02. memeory - can be modified in the function 
03. storage 
04. call data - cannot be modified in the function (kind of readonly function param. 
05. code 
06. logs 

*/