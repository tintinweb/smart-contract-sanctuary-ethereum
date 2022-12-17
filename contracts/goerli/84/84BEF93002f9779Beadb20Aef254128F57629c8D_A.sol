/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
  B public bb;
  
  function setB(address _b) public {
    bb = B(_b);
  }

  struct student {
    string name;
    uint number;
    uint score;
  }

  uint public index;
  student [] public students;

  function regStu(string memory _name, uint _score) public {
    students.push(student(_name, index++, _score));
    if (_score >= 80) {
      bb.regStu(_name, index, _score); 
    }
  } 

  function getStuInfo(uint _number) public view returns (student memory) {
    return students[_number];
  }
}

contract B {
  // B라는 컨트랙트에는 점수가 80점 이상되는 학생들을 모아놓은 array나 mapping을 만드세요.
  // 검색을 통하여 학생의 정보를 받아올 수 있게 해주는 함수도 필요합니다.

  A public aa;
  
  function setA(address _a) public {
    aa = A(_a);
  } 

  mapping (string => A.student) goodStudents; 
    
  function regStu(string memory _name, uint _number, uint _score) public {
    goodStudents[_name] = A.student(_name, _number, _score);      
  } 
}