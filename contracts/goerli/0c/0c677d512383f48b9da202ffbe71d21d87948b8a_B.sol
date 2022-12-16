/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {

  struct Student {
    uint num;
    string name;
    uint score;
  }

  Student[] students;


  function setStudent(string memory _name, uint _score) public {
    students.push(Student(students.length+1, _name,_score));
  }

  function getStudent(uint _n) public view returns(Student memory){
    return students[_n];
  }

  function getLen() public view returns(uint){
    return students.length;
  }
}

contract B {

  A a;
  mapping(string => uint) s;
  constructor(address _a){
    a = A(_a);
  }

  function scoreBoard() public {
    for(uint i=0;i<a.getLen();i++){
        if(a.getStudent(i).score >= 80){
          s[a.getStudent(i).name] = a.getStudent(i).score; 
        }
    }
  }

  function getStudent(uint _n) public view returns(string memory, uint){
    return (a.getStudent(_n).name,a.getStudent(_n).score);
  }
}