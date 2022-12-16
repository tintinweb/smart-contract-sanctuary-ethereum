/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {

  struct Student {
    string name;
    uint num;
    uint point;
  }

  Student student;

  function pushStudent(string memory _name, uint _num, uint _point) public {
    student.name = _name;
    student.num = _num;
    student.point = _point;
  }

}