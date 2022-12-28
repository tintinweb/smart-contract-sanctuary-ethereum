/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marks {
   
    // mapping from student address to their marks
    struct Student {
            uint studentId;
            string name;
            uint math;
            uint eng;
            uint nep;
            }
    mapping(uint => address) private student_info;
    mapping(uint => address) private teacher_mapping;
    mapping(uint => bool) studentExists;
    mapping(uint => bool) teacherExists;

    Student[] public students;

    function createStudent(uint _studentId, string memory _name) public {
        require(studentExists[_studentId]!=true,"Student already exists");
        student_info[_studentId]=msg.sender;
        students.push(Student(_studentId,_name,0,0,0));
        studentExists[_studentId]=true;

    }
    function createTeacher(uint _teacherId) public {
        require(teacherExists[_teacherId]!=true,"Teachers already exists");
        teacher_mapping[_teacherId]=msg.sender;
    }
    // add marks for a student
    function addMarks(uint _teacherId,uint _studentId,uint _math,uint _eng,uint _nep) public {
        require(msg.sender == teacher_mapping[_teacherId],"Sender is not teacher");
        require(studentExists[_studentId]==true,"this student id doesn't exist");
        for(uint i;i<students.length;i++){
            if(students[i].studentId==_studentId){
                students[i].math=_math;
                students[i].eng=_eng;
                students[i].nep=_nep;

            }
        }
    }

    // get the marks for a student
    function getMarks(uint _studentId) public view returns (uint,uint) {
        // require(msg.sender == student_info[_studentId],"Sender is not student");
        require(studentExists[_studentId]== true,"this student id doesn't exist");
        uint _totalMarks=300;
        uint _obtainedMarks;
        for(uint i;i<students.length;i++){
            if(students[i].studentId==_studentId){
                _obtainedMarks=students[i].math+students[i].eng+students[i].nep;

            }
        }        
        return (_obtainedMarks,(_obtainedMarks) *10000/ _totalMarks);
    }


}