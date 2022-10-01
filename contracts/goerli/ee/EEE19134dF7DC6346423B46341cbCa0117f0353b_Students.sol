/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Students{

    // sturct of students data. The variables inside the struct are state variables.
    struct StudentData{
        uint256 studentId;
        string name;
        uint256 age;
        uint256 level;
        string department;
        uint256 grade;
        bool  isPromoted;
    }

    StudentData []student;

    //A function that adds a new students data to the list
    //The memory keyword is used to store data temporarily
    function addStudentData(
        uint256 studentId,
        string memory name,
        uint256 age,
        uint256 level,
        string memory department,
        uint256 grade,
        bool  isPromoted
    ) public{
        StudentData memory n = StudentData(studentId,
            name,
            age,
            level,
            department,
            grade,
            isPromoted
        );
        student.push(n);
    }

    // Function that gets the students data inputed
    function getStudentData( uint256 studentId) public view returns(
        string memory,
        uint256,
        uint256,
        string memory,
        uint256,bool
    ) {
            uint i;
            for(i = 0; i < student.length; i++)
            {
                StudentData memory n = student[i];
                
                // Looks for a matching
                // employee id
                if(n.studentId == studentId)
                {
                    return(n.name,
                        n.age,
                        n.level,
                        n.department,
                        n.grade,
                        n.isPromoted);
                }
            }   
	
            // If student data not found return "not found", 0, false
            return("Not Found",
                0,
                0,
                "Not Found",
                0,
                false);
        }
}