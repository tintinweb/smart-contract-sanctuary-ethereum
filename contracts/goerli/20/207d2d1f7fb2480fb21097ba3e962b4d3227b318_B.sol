/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract B{
  struct student{
    string name;
    uint score;
    uint num;
  }
    mapping(string=>student) students;

  function honorsStudent(string memory name,uint score,uint num)external{
    students[name] = student(name,score,num);
  }

  function getStudent(string memory name)public view returns(student memory){
    return students[name];
  }


}