/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Assignment {
    address public teacher;
    address public student;

    uint256 public marksTotal;
    uint256 public marksGiven;
    uint256 public marksCalculated;

    uint256 public dateDue;
    uint256 public dateSubmitted;

    bool public submitted;
    bool public marked;

    // For validating submission with external upload
    uint256 public submissionHash;

    constructor(
        address _teacher,
        address _student,
        uint256 _marksTotal
    ) {
        teacher = _teacher;
        student = _student;
        marksTotal = _marksTotal;

        // Due at time of contract creation + 7 days
        dateDue = block.timestamp + 7 days;

        // Testing
        // dateDue = block.timestamp + 1 days;
    }

    modifier onlyTeacher() {
        require(
            msg.sender == teacher,
            "This function is restricted to the teacher"
        );
        _;
    }

    modifier onlyStudent() {
        require(
            msg.sender == student,
            "This function is restricted to the student"
        );
        _;
    }

    function submit(uint256 _submissionHash) public onlyStudent {
        require(submitted == false, "Already submitted");
        submitted = true;
        submissionHash = _submissionHash;
        dateSubmitted = block.timestamp;
    }

    function mark(uint256 _marksGiven) public onlyTeacher {
        require(marked == false, "Already marked");
        require(
            submitted == true,
            "Student has not submitted an assignment yet"
        );
        require(
            _marksGiven <= marksTotal,
            "Marks given must be less than total marks"
        );

        marked = true;
        marksGiven = _marksGiven;

        if (dateSubmitted <= dateDue) {
            marksCalculated = marksGiven;
        } else if (dateSubmitted <= dateDue + 1 days) {
            marksCalculated = (marksGiven * 80) / 100;
        } else if (dateSubmitted <= dateDue + 2 days) {
            marksCalculated = (marksGiven * 60) / 100;
        } else if (dateSubmitted <= dateDue + 3 days) {
            marksCalculated = (marksGiven * 50) / 100;
        }
    }
}