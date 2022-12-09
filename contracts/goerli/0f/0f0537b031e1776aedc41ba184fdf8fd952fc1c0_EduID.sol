/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EduID {

    // struct Grade{
    //     string student_name;
    //     uint256 student_indentification;
    //     string subject;
    //     string student_grad;
    //     uint256 timeStamp;
    // }

    // struct student{
    //     string student_name;
    //     string student_subject;
    //     string student_score;
    //     uint256 student_indentification;
    //     uint256 timeStampUploded;
    //     uint256 timeStamp;
    // }

    struct Student{
        string student_name;
        uint256 student_identification;
        uint256 timeStamp;

    }

    struct Grades{
        string subject;
        string student_grade;
    }

   // mapping(uint256 => Grade) public _grade;
    mapping(uint256 => Grades[]) public _getstudentgrade;
    mapping(uint256 => Student) public _student;

    Grades[] public allgrade;

    function addStudent(uint256 _id , string memory _name) public {
        _student[_id].student_name = _name;
        _student[_id].student_identification = _id;
        _student[_id].timeStamp = block.timestamp;
    }

    function addGrade(uint256 _id , string memory _name , string memory _subject, string memory grade) public {
        _getstudentgrade[_id].push(Grades(_subject , grade));
    }

    function getAllGrade(uint256 _id) public returns (Student memory, Grades[] memory) {
        return (_student[_id], _getstudentgrade[_id]);
    }
}