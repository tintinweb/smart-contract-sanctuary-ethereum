// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// custom error
error MarksNotSubmittedForAllSubjectsYet();
error FullMarksIs10();

contract MarkSheet {
    uint private constant SUBJECT_COUNT = 3;

    enum Subject {
        Maths,
        Science,
        Physics
    }

    enum Grade {
        A,
        B,
        C
    }

    struct Mark {
        Subject subject;
        uint marksObtained;
        address checkedByTeacher;
        address studentWhoseCopyWasChecked;
    }

    Mark[] private studentMarks;

    mapping(address => Grade) private studentToGrade;
    mapping(address => Mark[]) private studentToMarksArray;

    event SubmitMark(string message);

    // public function
    function submitMark(
        address _studentWhoseCopyWasChecked,
        uint _mark, // fullmarks is 10
        Subject _subject
    ) public {
        emit SubmitMark("Submit Mark was called");
        if (_mark > 10) revert FullMarksIs10();
        Mark memory _tempMark = Mark(
            _subject,
            _mark,
            msg.sender,
            _studentWhoseCopyWasChecked
        );
        _mapStudentToMarksArray(_tempMark);
        _mapStudentToGrade(_studentWhoseCopyWasChecked);
    }

    function _mapStudentToMarksArray(Mark memory _mark) private {
        Mark[]
            storage allSubjectMarksOfStudentWhoseCopyWasChecked = studentToMarksArray[
                _mark.studentWhoseCopyWasChecked
            ];
        uint len = allSubjectMarksOfStudentWhoseCopyWasChecked.length;
        allSubjectMarksOfStudentWhoseCopyWasChecked[
            len > 0 ? len - 1 : 0
        ] = _mark;
        studentToMarksArray[
            _mark.studentWhoseCopyWasChecked
        ] = allSubjectMarksOfStudentWhoseCopyWasChecked;
    }

    // public function
    function getGrade(address student) public view returns (string memory) {
        if (studentToMarksArray[student].length != SUBJECT_COUNT) {
            revert MarksNotSubmittedForAllSubjectsYet();
        }
        return getStringForGrade(studentToGrade[student]);
    }

    function _mapStudentToGrade(address student) private {
        Mark[] memory studentMarks = studentToMarksArray[student];
        if (studentMarks.length != SUBJECT_COUNT) {
            revert MarksNotSubmittedForAllSubjectsYet();
        }

        uint toalMarksObtainedOnAllSubjects = 0;
        for (uint i = 0; i < studentMarks.length; i++) {
            toalMarksObtainedOnAllSubjects += studentMarks[i].marksObtained;
        }

        // uint avgMark = toalMarksObtainedOnAllSubjects / SUBJECT_COUNT;
        if (toalMarksObtainedOnAllSubjects >= 20) {
            studentToGrade[student] = Grade.A;
        } else if (
            toalMarksObtainedOnAllSubjects > 10 &&
            toalMarksObtainedOnAllSubjects < 20
        ) {
            studentToGrade[student] = Grade.B;
        } else {
            studentToGrade[student] = Grade.C;
        }
    }

    function getStringForGrade(
        Grade _grade
    ) private pure returns (string memory) {
        if (_grade == Grade.A) return "Grade A";
        else if (_grade == Grade.B) return "Grade B";
        else return "Grade C";
    }
}