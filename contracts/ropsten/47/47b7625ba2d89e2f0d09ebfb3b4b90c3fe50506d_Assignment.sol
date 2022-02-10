/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Assignment {
    address public teacher;
    address public student;

    uint256 public marksTotal;

    uint256 public dateDue;
    uint256 public dateSubmitted;

    bool public isSubmitted;
    bool public isMarked;

    event Submitted(uint256 _submissionHash);
    event Marked(uint256 _marksGiven, uint256 _marksCalculated);

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
        require(isSubmitted == false, "Already submitted");
        dateSubmitted = block.timestamp;
        isSubmitted = true;
        emit Submitted(_submissionHash);
    }

    function mark(uint256 _marksGiven) public onlyTeacher {
        require(isMarked == false, "Already marked");
        require(
            isSubmitted == true,
            "Student has not submitted an assignment yet"
        );
        require(
            _marksGiven <= marksTotal,
            "Marks given must be less than total marks"
        );

        uint256 marksCalculated = 0;

        if (dateSubmitted <= dateDue) {
            marksCalculated = _marksGiven;
        } else if (dateSubmitted <= dateDue + 1 days) {
            marksCalculated = (_marksGiven * 80) / 100;
        } else if (dateSubmitted <= dateDue + 2 days) {
            marksCalculated = (_marksGiven * 60) / 100;
        } else if (dateSubmitted <= dateDue + 3 days) {
            marksCalculated = (_marksGiven * 50) / 100;
        }

        isMarked = true;
        emit Marked(_marksGiven, marksCalculated);
    }
}