/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract SimpleStorage {

    // Fee struct
    struct Fee{
        uint256 totalFee;
        uint256 paidFee;
    }
    
    struct Fine{
        uint256 totalFee;
        uint256 paidFee;
    }

    // Student struct
    struct Student {
        string name;
        string email;
        string registrationNo; // 2018CS401
        string department;
        string cnic;
        string phone;
        string session;
        string gender;
        string studentType; // dayscholar | hostelite
        string province;
        string district;
        string image;
        uint256[] feesTotal;     // it will contain total fees of 8 semesters
        uint256[] feesPaid;      // it will contain paid fees of 8 semesters
        string[] fineReasons;     // it will contain total fees of 8 semesters
        uint256[] fineAmounts;      // it will contain paid fees of 8 semesters
    }

    Student[] students;

    function addStudent(
        Student memory newStudent
    ) public returns(uint256) {
        students.push(Student({
                name:newStudent.name,
                email:newStudent.email,
                registrationNo:newStudent.registrationNo,
                department:newStudent.department,
                cnic:newStudent.cnic,
                phone:newStudent.phone,
                session:newStudent.session,
                gender:newStudent.gender,
                studentType:newStudent.studentType,
                province:newStudent.province,
                district:newStudent.district,
                image:newStudent.image,
                feesTotal:newStudent.feesTotal,
                feesPaid:newStudent.feesPaid,
                fineReasons:newStudent.fineReasons,
                fineAmounts:newStudent.fineAmounts
        }));
        return students.length-1; // it will give us the indwx of student in array of students
    }

    function getAllStudents() public view returns (Student[] memory) {
        return students;
    }

    function getNumberOfStudents() public view returns (uint256) {
        return students.length;
    }
    
    function getStudent(uint256 index) public view returns (Student memory) {
        require(index < students.length);
        return students[index];
    }
    
    function updateStudent(uint256 index, Student memory updatedStudent) public  returns (Student memory) {
        require(index < students.length);
          students[index]=Student(
                updatedStudent.name,
                updatedStudent.email,
                updatedStudent.registrationNo,
                updatedStudent.department,
                updatedStudent.cnic,
                updatedStudent.phone,
                updatedStudent.session,
                updatedStudent.gender,
                updatedStudent.studentType,
                updatedStudent.province,
                updatedStudent.district,
                updatedStudent.image,
                updatedStudent.feesTotal,
                updatedStudent.feesPaid,
                updatedStudent.fineReasons,
                updatedStudent.fineAmounts
            );
            return students[index];
    }
    
    function deleteStudent(uint256 index) public returns (uint256) {
        require(index < students.length);
         for (uint i = index; i<students.length-1; i++){
            students[i] = students[i+1];
        }
        students.pop();
        return students.length;
    }
}