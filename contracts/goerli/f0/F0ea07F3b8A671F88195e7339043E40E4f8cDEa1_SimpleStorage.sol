/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {

    Student[] public student;

    mapping(string => string) public nameToSection;

    struct Student {
        string name;
        string year;
        string section;
        uint256 contact;
    }

    function addStudent(string memory _name, string memory _year, string memory _section, uint256 _contact) public {
        student.push(Student(_name,_year,_section,_contact));
        nameToSection[_name] = _section;
    }
}