//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Score {
  error NotTeacher();

  mapping(address => uint) public students;
  address public teacher;
  address owner;
  

  constructor() {
    owner = msg.sender;
  }

  function setTeacher(address t) public {
    if (owner == msg.sender) {
      teacher = t;
    }

  }
  
  modifier onlyTeacher() {
    if(msg.sender != teacher) {
      revert NotTeacher();
    } 
    _;
  }

  function setScore(address addr, uint data) external onlyTeacher {
      students[addr] = data;
  }
}

interface IScore {
  function setScore(address addr, uint data) external;
}

contract Teacher {

  IScore score;

  constructor(address s) {
    score = IScore(s);
  }


  function callSetScore(address addr, uint data) public {
      score.setScore( addr, data);
  }
}