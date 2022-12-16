/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract B {
  
  struct Student {
    string name;
    uint num;
    uint point;
  }

  Student[] students;

  function pushStudent(string memory _name, uint _num, uint _point) public {
    if(_point >= 80) {
      students.push(Student(_name, _num, _point));
    }
  }

  function getStudent(uint _num) public view returns(string memory, uint, uint) {
    return(students[_num-1].name, students[_num-1].num, students[_num-1].point);
  }

}