/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <8.10.0;

contract SimpleStorage {
    // uint256 studentCount;

    // struct Semester {
    //     uint256 totalFee;
    //     uint256 paidFee;
    // }

    struct Student {
        string studentId;
        string name;
        string email;
        string regNo; // 2018CS401
        string gender;
        string cnic;
        string phone;
        string depart;
        string studentType; // dayscholar | hostelite
        string province;
        string district;
        // string feeVoucherId;
        uint256 timestamp;
        // Semester[] fees;
        // mapping(uint=>Semester) fees;
    }

    Student[] students;

    // array of students

    function addStudent(
        string memory studentId,
        string memory name,
        string memory email,
        string memory regNo,
        string memory gender,
        string memory cnic,
        string memory phone,
        string memory depart,
        string memory studentType,
        string memory province,
        string memory district // uint256 totalFee
        // string memory feeVoucherId,
        // uint256 feeAmount
    ) public {
        // studentCount += 1;

        // Semester[] memory fee;
        // fee[0] = Semester(feeAmount, 0);
        // fee.push(Semester(totalFee, 0));
        students.push(
            Student(
                studentId,
                name,
                email,
                regNo,
                gender,
                cnic,
                phone,
                depart,
                studentType,
                province,
                district,
                // feeVoucherId,
                block.timestamp
                // fee
            )
        );
    }

    function getAllStudents() public view returns (Student[] memory) {
        return students;
    }

    function getNumberOfStudents() public view returns (uint256) {
        // return studentCount;
        return students.length;
    }
}