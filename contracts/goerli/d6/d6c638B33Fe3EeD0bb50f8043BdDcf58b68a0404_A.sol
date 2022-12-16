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