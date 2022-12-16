/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Students {
  struct student {
    uint num;
    string name;
    uint score;
  }

  student[] students;

  function setStudent(string memory _name, uint _score) public {
    students.push(student(students.length+1, _name, _score));
  }
}