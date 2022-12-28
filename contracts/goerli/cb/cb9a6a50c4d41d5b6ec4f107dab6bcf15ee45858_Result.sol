/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Result{

    // Assume decimal after 2 number in Percentage 

    struct Student{
        string name;
        uint rollNum;
        uint totalMarks;
        uint percentage;
    }

    mapping(uint => Student) students;

    function addStudent(string memory _name,uint _rollNum)public{
        Student memory student;
        student.name = _name;
        student.rollNum = _rollNum;
        students[_rollNum] = student;
    }

    function getTotalMarks(uint _rollNum,uint _english,uint _nepali,uint _math,uint _science,uint _computer)public {
        uint _totalmarks = _english + _nepali + _math + _science + _computer;

        students[_rollNum].totalMarks = _totalmarks;
    }

    function calculatePercent(uint _rollNum) public{
        uint percent = (students[_rollNum].totalMarks * 10000) / 500;
        students[_rollNum].percentage = percent;
    }

    function getStudent(uint _rollNum) public view returns(string memory _Stdname,uint _rollNo,uint _obtMarks,uint _caltdPercent){
        return (
            students[_rollNum].name,
            students[_rollNum].rollNum,
            students[_rollNum].totalMarks,
            students[_rollNum].percentage
        );
    }

}