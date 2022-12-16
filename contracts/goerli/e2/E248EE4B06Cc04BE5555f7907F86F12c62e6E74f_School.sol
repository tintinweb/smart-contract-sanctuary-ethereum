/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.22 <0.9.0;

contract School {

  EliteSchool private eliteSchool;
  address private ownerAddress;

  struct Student {
    string name;
    uint number;
    uint score;
  }

  constructor(address _address) {
    eliteSchool = EliteSchool(_address);
    ownerAddress = msg.sender;
  }

  // 엘리트학생 등록
  function setEliteSchool(address _address) public {
    require(ownerAddress==msg.sender);
    eliteSchool = EliteSchool(_address);
  }  

  uint private index;
    
  Student[] studentArr;

  // 학생등록
  function setStudent(string memory _name, uint _score) public {
    studentArr.push(Student(_name, index++, _score));

    // 80점이상 학생은 엘리트학교에 등록
    if (_score >= 80) {
      eliteSchool.setEliteStudent(_name, index, _score);
    }
  } 

  // 학생정보 가져오기
  function getStudentInfo(uint _number) public view returns (Student memory) {
    return studentArr[_number-1];
  }

  // 모든 학생정보 가져오기
  function getAllStudentInfo() public view returns (Student[] memory) {
    return studentArr;
  }
}


contract EliteSchool {

  School.Student[] eliteStudentArr;

  string[] private resArr;

  // 엘리트 학생등록 - 외부에서만 호출 가능
  function setEliteStudent(string memory _name, uint _number, uint _score) external {
    eliteStudentArr.push(School.Student(_name, _number, _score));
  }
  
  // 엘리트 학생 가져오기
  function getEliteStudent(uint _number) public view returns(School.Student memory) {
    return eliteStudentArr[_number];
  }

  // 엘리트 학생 전체 조회 
  function getAllEliteStudent() public view returns(School.Student[] memory) {
    return eliteStudentArr;
  }

}