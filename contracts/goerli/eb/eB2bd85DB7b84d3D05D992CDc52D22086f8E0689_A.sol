/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
  B public contB;
  constructor (address _addr) {
    contB = B(_addr);
  }

  struct Student {
    string name;
    uint id;
    uint score;
  }

  mapping (string => Student) studentMap;
  uint stIndex;

  function setStudent(string memory _name, uint _score) public {
    studentMap[_name] = Student(_name, ++stIndex, _score);
    if(_score >= 80){
      contB.setHstudent(_name, stIndex, _score);
    }
  }

  function getStudent(string memory _name) public view returns(Student memory) {
    return studentMap[_name];
  }
}

contract B {
  struct Student {
    string name;
    uint id;
    uint score;
  }

  mapping (string => Student) hstudents;

  function setHstudent(string memory _name, uint _id, uint _score) external {
    hstudents[_name]= Student(_name, _id, _score);
  }

  function getHstudent(string memory _name) public view returns(Student memory){
    return hstudents[_name];
  }
}