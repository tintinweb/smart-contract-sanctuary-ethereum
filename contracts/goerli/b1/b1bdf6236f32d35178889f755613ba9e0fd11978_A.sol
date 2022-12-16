/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
 
 struct Student {
  uint number;
  string name;
  uint score;
 } 

Student [] public students;


uint index; 
function setStudent(string memory _name, uint _score) public {
  students.push(Student(index++, _name, _score));
}
}