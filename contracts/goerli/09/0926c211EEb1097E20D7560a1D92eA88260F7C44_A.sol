/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
  struct student {
    string name;
    uint number;
    uint score;
  }
  
  mapping(string => uint) studentIdx;
  student[] public studentList;

  constructor(){
    studentList.push(student("DUMMY",0,0));
  }

  function setStudent(string memory _name, uint _score) public {
    require(studentIdx[_name] == 0,"ALREADY EXISTS");
    studentList.push(student(_name, studentList.length, _score));
    studentIdx[_name] = studentList.length-1;
  }

  function getStudent(string memory _name) public view returns(student memory) {
    return studentList[studentIdx[_name]];
  }

  function getAllStudents() public view returns(student[] memory) {
    return studentList;
  }
}