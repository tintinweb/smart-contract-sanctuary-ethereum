/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

contract StudentContract{
    struct Student{
        string name;
        uint256 rollNo;
    }

    Student[] students;

    // add student
    function addStudent(string memory name,uint256 roll) public {
        students.push(Student(name,roll));
    }

    function getAllStudents() public view returns(Student[] memory){
        return students;
    }
    
    function getStudent(uint256 index) public view returns(Student memory){
        return students[index];
    }

    function updateStudent(uint256 id,string memory name, uint256 roll) public {
        students[id]=Student(name,roll);
    }
    
    function deleteStudent(uint256 id) public {
        if (id >= students.length) return;
         for (uint i = id; i<students.length-1; i++){
            students[i] = students[i+1];
        }
        delete students[students.length-1];
    }
}