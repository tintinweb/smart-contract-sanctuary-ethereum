/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract SubjectRegistration {

    string internal constant SR = "[0000] You register the course successfully";
    string internal constant WL = "[0001] You are in the waiting list!";

    // This is a type for a Student
    struct Student {
        bool registered; 
        string studentID;
        uint courseID; // Index of the registered course
        string result;
    }
    
    // This variable stores a 'Student' struct for each address
    mapping(address => Student) public student;

    // This varaible stores the number of students for each course
    mapping(uint => uint) public courses;
    
    // Create a new registration to choose one of the 5 courses
    constructor() {
        
        for (uint i = 0; i < 5; i++) {
            courses[i] = 0;
        }
    }

    //  register course
    function register(uint courseID, string memory studentID) public {
        require(courseID >= 0, 'The id must be greater or equal to 0');
        require(courseID <= 4, 'The id must be less or equal to 4');

        Student storage sender = student[msg.sender];
        require(!sender.registered, "Already choose a course.");
        sender.registered = true;
        sender.studentID = studentID;
        sender.courseID = courseID;
        courses[courseID] += 1;
        
        if (courses[courseID] <= 10) {
            sender.result = SR;
        } else {
            sender.result = WL;
        }
    }

    // Computes the most popular course
    function mostPopularCourse() private view returns (uint mostPopularCourseID_) {
        uint winningCourseCount = 0;
        for (uint p = 0; p < 5; p++) {
            if (courses[p] > winningCourseCount) {
                winningCourseCount = courses[p];
                mostPopularCourseID_ = p;
            }
        }
    }

    // Call mostPopularCourse() to get the index of the most popular course
    function MostPopularCourseId() public view returns (uint mostPopularCourseId_){
        mostPopularCourseId_ = mostPopularCourse();
    }

    function result() public view returns (string memory result_){
        Student storage sender = student[msg.sender];
        result_ = sender.result;
    }
}