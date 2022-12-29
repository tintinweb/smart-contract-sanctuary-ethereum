/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marks {
   
    // mapping from student address to their marks
    struct Student { 
            address studentAdd;
            string name;
            uint32 math;
            uint32 eng;
            uint32 nep;
            bool exists;
            }
    mapping(uint32 => Student) private student_info;
    mapping(uint32 => address) private teacher_mapping;

    function createStudent(uint32 _studentId, string memory _name) public {
        require(student_info[_studentId].exists!=true,"Student already exist");
        student_info[_studentId].studentAdd=msg.sender;
        student_info[_studentId].name=_name;
        student_info[_studentId].exists=true;
    }
    function createTeacher(uint32 _teacherId) public {
        teacher_mapping[_teacherId]=msg.sender;
    }
    // add marks for a student
    function addMarks(uint32 _teacherId,uint32 _studentId,uint32 _math,uint32 _eng,uint32 _nep) public {
        require(msg.sender == teacher_mapping[_teacherId],"Sender is not teacher");
        require(student_info[_studentId].exists == true,"this student id doesn't exist");
        student_info[_studentId].math=_math;
        student_info[_studentId].eng=_eng;
        student_info[_studentId].nep=_nep;
    }

    // get the marks for a student
    function getMarks(uint32 _studentId) public view returns (uint32,uint32) {
        require(student_info[_studentId].exists == true,"this student id doesn't exist");
        uint32 _totalMarks=300;
        uint32 _obtainedMarks;
        _obtainedMarks=student_info[_studentId].math+student_info[_studentId].eng+student_info[_studentId].nep;
        
        return (_obtainedMarks,(_obtainedMarks) *10000/ _totalMarks);
    }


}