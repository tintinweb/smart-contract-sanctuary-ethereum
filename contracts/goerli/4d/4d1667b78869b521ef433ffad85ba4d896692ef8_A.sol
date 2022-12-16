// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./B.sol";

contract A {

  B b;
  constructor(address _ad){
    b = B(_ad);
  }

  struct student{
    string name;
    uint score;
    uint num;
  }

  student[] students;

  function inputStudent(string memory name,uint score)public{
    if(score>80){
      grade(name,score,students.length+1);
    }
    students.push(student(name,score,students.length+1));
    
  }
  
  function grade(string memory name,uint score,uint num)private{
      b.honorsStudent(name, score, num);
  }

}


// A라는 컨트랙트에는 학생이라는 구조체를 만드세요.
// 학생이라는 구조체안에는 이름과 번호 그리고 점수를 넣습니다. 
// 점수와 정보들을 넣을 수 있는 함수를 만드세요.

// B라는 컨트랙트에는 점수가 80점 이상되는 학생들을 모아놓은 array나 mapping을 만드세요.
// 검색을 통하여 학생의 정보를 받아올 수 있게 해주는 함수도 필요합니다.