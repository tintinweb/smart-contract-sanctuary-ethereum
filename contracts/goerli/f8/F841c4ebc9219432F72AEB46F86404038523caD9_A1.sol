/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A1 {
    struct student {
        string name;
        uint number;
        uint score;
    }

    student[] Students;
    student[] highScoreStudents;

        function setStudent(string memory _name, uint _num, uint _score) public {
        Students.push(student(_name, _num, _score));
        if(_score >= 80) {
            highScoreStudents.push(student(_name, _num, _score));
        }
    }

    function getStudent(uint _n) public view returns(student memory){
    return Students[_n];
  }
}