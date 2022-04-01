/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract CareerFair {

    struct Student {
        address studentID;       // Wallet address will identify students
        bool isEnrolled;         // 'true' if enrolled in the career fair already, 'false' otherwise
    }

    event CompanyAdded(string course);
    event Enrolled(address studentID);
    event Unenrolled(address studentID);

    /* GLOBAL VARIABLES */
    address owner;
    mapping (address => Student) students;
    string[] companies;
    address[] studentAttendees;

    constructor() {
        owner = msg.sender;
        add("Amazon");
        add("Google");
        add("Apple");
        add("Microsoft");
        add("Meta");
        add("Gemini");
        add("SecureEd");
    }

    function enroll() public {
        Student storage currentStudent = students[msg.sender];
        require(!currentStudent.isEnrolled, "Student already enrolled in career fair!");

        currentStudent.isEnrolled = true;
        studentAttendees.push(msg.sender);
        emit Enrolled(msg.sender);
    }

    function add(string memory companyName) public {
        require(msg.sender == owner, "Only the owner can add companies!");

        // Iterate through the entire collection,
        // to see if the company already exists.
        for (uint i = 0; i < companies.length; i++) {
            if (_isSameString(companyName, companies[i])) {
                revert("Company name already exists!");
            }
        }

        // If the company name is new, add it to the collection.
        companies.push(companyName);
        emit CompanyAdded(companyName);
    }

    function _isSameString(string memory first, string memory second) 
    private pure returns (bool) {
        return (keccak256(abi.encodePacked((first))) == keccak256(abi.encodePacked((second))));
    }

    function getCompanies() 
    public view returns (string[] memory) {
        string[] memory outInfo =  new string[](companies.length);

        for (uint i = 0; i < companies.length; i++) {
            outInfo[i] = companies[i];
        }

        return outInfo;
    }

    function getAttendees() 
    public view returns (address[] memory) {

        uint index = 0;
        uint validStudents = 0;

        for (uint i = 0; i < studentAttendees.length; i++) {
            if (studentAttendees[i] == address(0)) {
                continue;              
            }
            validStudents++;
        }

        address[] memory outInfo =  new address[](validStudents);

        for (uint i = 0; i < studentAttendees.length; i++) {
            if (studentAttendees[i] == address(0)) {
                continue;              
            }
            outInfo[index] = studentAttendees[i];
            index++;
        }

        return outInfo;
    }

    function unenroll()
    public {
        Student storage currentStudent = students[msg.sender];
        require(currentStudent.isEnrolled, "Student is not enrolled in career fair!");

        // Unregister the student.
        currentStudent.isEnrolled = false; 

        // Drop the student from the roster.
        for (uint i = 0; i < studentAttendees.length; i++) {
            if (studentAttendees[i] == msg.sender) {
                delete studentAttendees[i];
            }
        }

        emit Unenrolled(msg.sender);
    }
}