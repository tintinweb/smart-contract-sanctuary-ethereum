/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract Marksheet {
    
    address teacher;

    

    constructor() {
        teacher = msg.sender;
    }

  
    struct Student {
         address walletAddress;
       uint marks;
       uint percentage;
    }

    Student[] public students;

    modifier onlyTeacher() {
        require(msg.sender == teacher, "Only the owner can add kids");
        _;
    }
    
   
    function addStudent(address walletAddress, 
        uint marks,
        uint percentage) public onlyTeacher {
        students.push(Student(
             walletAddress,
             marks, 
             percentage
        ));
    }

  

    
    function calculate(address walletAddress) public {
        convertToPercentage(walletAddress);
    }

    function convertToPercentage(address walletAddress) private {
        for(uint i = 0; i < students.length; i++) {
            if(students[i].walletAddress == walletAddress) {
                students[i].percentage = students[i].marks * 100 /250;
               
            }
        }
    }

    
}