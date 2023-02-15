/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Registration {

    struct Students {
        uint rollnumber;
        string fname;
        string lname;
        uint age;
        uint phoneNumber;
        uint class;
        string section;
    }

    mapping (uint => Students) public students;

    uint rollnumber = 1;

    function addStudent(string memory fname, string memory lname, uint age, uint phoneNumber, uint class, string memory section) public returns (bool){
        students[rollnumber] = Students(rollnumber, fname, lname, age, phoneNumber, class, section);
        rollnumber += 1;
        return true;
    }

    function getStudent(uint rollnumber) public view returns (string memory, string memory, uint, uint, uint, string memory) {
        return (
            students[rollnumber].fname, 
            students[rollnumber].lname, 
            students[rollnumber].age, 
            students[rollnumber].phoneNumber, 
            students[rollnumber].class, 
            students[rollnumber].section
        );
    }

}