/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Report {
     struct Teacher {
        string name;
        uint8 id;
     }

     struct Student {
        string name;
        uint8 roll;
        uint256[5] marks;
     }

     mapping(address => Teacher) private teachers;
     mapping(uint8 => Student)  private students;


     function registerTeacher(string memory _name, uint8 _id ) public {
        teachers[msg.sender].name = _name;
        teachers[msg.sender].id = _id;
     }

     function registerStudent(string memory _name, uint8 _roll, uint256[5] memory _marks) public {
        require(teachers[msg.sender].id != 0, "Only registered teachers can register students!");
        students[_roll].name = _name;
        students[_roll].roll = _roll;
        for(uint8 i=0; i<5; i++) {
            students[_roll].marks[i] = _marks[i];
        }
     }

     function getStudentResult(uint8 _roll) public view returns(uint256) {
         require(students[_roll].roll == _roll, "Student NOT Registered yet!");
         uint256 sum = 0;
         for(uint8 i=0; i<5; i++) {
             sum += students[_roll].marks[i];
         }

         return (sum * 100 / 50000);
     }


}