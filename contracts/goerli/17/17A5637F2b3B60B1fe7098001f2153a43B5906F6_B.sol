/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {

  struct Student {
    uint no;
    string name;
    uint score;
  }

  uint public index;
  mapping(uint => Student) Students;

  // 학생등록
  function setStudent(string memory _name, uint _score) public {
    Students[index++] = Student(index, _name, _score);
  }

  // 학생 정보 저체 가져오기
  function getStudent(uint _no) public view returns(Student memory) {
    return Students[_no];
  }

}

contract B {

  uint[] goodStudentArr;

  A public a;
  constructor(address _a) {
    a = A(_a);
  }


  //80점 이상 학생정보 전부 가져오기
  function getGoodStudents() public {
    uint length = a.index();
    for (uint i = 0; i <= length; i++) {

      uint score = a.getStudent(i).score;

      if(score>=80){
        goodStudentArr.push(i);
      }
    }
  }

  //모든 우등생들 번호
  function getAllGoodStudents() public view returns(uint[] memory) {
    return goodStudentArr;
  }

  //학생번호로 학생정보가져오기
  function getStudent(uint _no) public view returns(string memory, uint) {
    return(a.getStudent(_no).name, a.getStudent(_no).score);
  }


}