//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract StudentInformation {
    
    struct Student {
        string name;
        uint age;
        string major;
    }
    
    mapping(address => Student) public students;
    address[] public studentList;
    
    function addStudent(string memory _name, uint _age, string memory _major) public {
        Student storage newStudent = students[msg.sender];
        newStudent.name = _name;
        newStudent.age = _age;
        newStudent.major = _major;
        studentList.push(msg.sender);
    }
    
    function getStudentCount() public view returns (uint) {
        return studentList.length;
    }
    
    function getStudentByIndex(uint _index) public view returns (string memory, uint, string memory) {
        require(_index < studentList.length, "Index out of range");
        address studentAddress = studentList[_index];
        return (students[studentAddress].name, students[studentAddress].age, students[studentAddress].major);
    }
}