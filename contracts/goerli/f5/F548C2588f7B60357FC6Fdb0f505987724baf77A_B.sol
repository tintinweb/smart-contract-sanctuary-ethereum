/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
contract A {
  struct Student { 
    string name;
    uint num;
    uint score;
  }
  Student public student;
  Student[] public Students;

  function setStudent(string memory _name,  uint _score) public {
    Students.push(Student(_name, Students.length +1 , _score));
  }


}

contract B {
  A a;
  // constructor(address _addr) {
  //   a = A(_addr);
  // }

  struct Student { 
    string name;
    uint num;
    uint score;
  }

  Student[] public Students;

  mapping(string => Student) Goodgrade;
  

  function setGoodgrade(string memory _name, uint _score) public {
    if(_score >= 80){
      Goodgrade[_name] = Student(_name, Students.length +1 , _score);
    }
  }


}