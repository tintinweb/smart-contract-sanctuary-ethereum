/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
  struct studenet {
    uint num;
    string name;
    uint score;
  }

  mapping(uint => studenet) public Students;
  uint public idx;

  //학생 설정
  function setStudent(string memory _name, uint _score) public {
    idx++;
    Students[idx] = studenet(idx, _name, _score);
  }

  function getStudent(uint _num) public view returns(studenet memory) {
    return(Students[_num]);
  }  
}