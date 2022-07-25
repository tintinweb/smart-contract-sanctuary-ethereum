/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Register {

  struct RegisterStudent {
    string nameStudent;
    string classStudent;
    string date;
  }

  mapping (bytes32 => RegisterStudent) public registers;

  function setRegister(string memory _name, string memory _class, string memory _date) public {

    RegisterStudent memory register;
    register.nameStudent = _name;
    register.classStudent = _class;
    register.date = _date;

    bytes32 hash = keccak256(abi.encodePacked(_name, _class, _date));
    registers[hash] = register;    

  }

  function getHash(string memory _name, string memory _class, string memory _date) public pure returns (bytes32) {
      return keccak256(abi.encodePacked(_name, _class, _date));
  }
}