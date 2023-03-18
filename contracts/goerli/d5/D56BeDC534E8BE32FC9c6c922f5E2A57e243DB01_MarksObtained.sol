/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract MarksObtained{ 
    
    address teacher;
              constructor() {
        teacher = msg.sender;
    }
        struct Student{
            string name;
            uint16 rollNo;
            uint16 contact_no;
            string student_address;
        }

        struct Marks{
            uint16 maths;
            uint16 science;
            uint16 gk;
        }
        

   mapping(uint => Student) public students;

   mapping(uint => Marks) public marks;

    function addStudent(uint16 _rollNo, string memory _name, uint16 _contact_no, string memory _student_address ) 
    public {
        require(msg.sender == teacher, "Only teacher can add marks");
        students[_rollNo]=Student(_name,_rollNo,_contact_no,_student_address);
    }

    function addMarks(uint16 _rollNo, uint16 _maths, uint16 _science, uint16 _gk) public{
        marks[_rollNo]=Marks(_maths,_science,_gk);
    }

    function totalMarks(uint16 _rollNo) public view returns (uint16 total, uint16 percentage){
     Marks memory smark = marks[_rollNo] ;
         total = smark.maths + smark.science +smark.gk;
         percentage = total * 100 /500;
        return (total, percentage);
    }
    

    
}