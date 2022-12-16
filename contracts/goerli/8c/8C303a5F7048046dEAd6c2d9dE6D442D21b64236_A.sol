// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {


  struct student {
    string name;
    uint num;
    uint score;
    bool isOver80;
  }
  uint no;
  mapping(string => student) public Students;
  mapping(string => student) public over80s;

  function setStudent(string memory _name, uint _score) public {
    Students[_name] = student(_name, no++, _score,false);
    isOver80(_name,_score);
  }

  function getStudent(string memory _name) public view returns(student memory) {
    return Students[_name];
  } 

  function isOver80(string memory _name, uint _score) public {
    if (_score>=80) {
      Students[_name].isOver80 = true; 
      over80s[_name] = Students[_name];
      }
      Students[_name].isOver80 = false;
  } 
}