/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
  struct student {
    string name;
    uint number;
    uint score;
  }

  mapping (string => student) students;

  function setStudent(string memory _name, uint _number, uint _score) external {
    students[_name]= student(_name, _number, _score);
  }

  
}

contract B {
  struct student {
    string name;
    uint number;
    uint score;
  }

  mapping (string => student) students;
  /*
  function setStudent(string memory _name, uint _score) public {
    students[_name] = Student(_name, ++number, _score);
    if(_score >= 80){
      contB.setHstudent(_name, _number, _score);
    }
  }

  function getStudent(string memory _name) public view returns(string memory) {
    return students[_name];
  }*/

}