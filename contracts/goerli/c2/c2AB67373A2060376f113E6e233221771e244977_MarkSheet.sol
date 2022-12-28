// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

// custom error
error MarksNotSubmittedForAllSubjectsYet();

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

    Mark[] private _studentMarks;

    mapping(address => Grade) private _studentToGrade;
    mapping(address => Mark[]) private _studentToMarksArray;

    // // emit logs
    function submitMark(
        address _studentWhoseCopyWasChecked,
        uint _mark,
        Subject _subject
    ) public {
        Mark memory _tempMark = Mark(
            _subject,
            _mark,
            msg.sender,
            _studentWhoseCopyWasChecked
        );
        _mapStudentToMarksArray(_tempMark);
        // mapStudentToGrade(_studentWhoseCopyWasChecked);
    }

    function _mapStudentToMarksArray(Mark memory _mark) private {
        Mark[]
            storage allSubjectMarksOfStudentWhoseCopyWasChecked = _studentToMarksArray[
                _mark.studentWhoseCopyWasChecked
            ];
        uint len = allSubjectMarksOfStudentWhoseCopyWasChecked.length;
        allSubjectMarksOfStudentWhoseCopyWasChecked[
            len > 0 ? len - 1 : 0
        ] = _mark;
        _studentToMarksArray[
            _mark.studentWhoseCopyWasChecked
        ] = allSubjectMarksOfStudentWhoseCopyWasChecked;
    }

    function getGrade(address student) public view returns (string memory) {
        return getStringForGrade(_studentToGrade[student]);
    }

    function mapStudentToGrade(address student) private {
        Mark[] memory _studentMarks = _studentToMarksArray[student];
        if (_studentMarks.length != 3) {
            revert MarksNotSubmittedForAllSubjectsYet();
        }

        uint toalMarksObtainedOnAllSubjects = 0;
        for (uint i = 0; i < _studentMarks.length; i++) {
            toalMarksObtainedOnAllSubjects += _studentMarks[i].marksObtained;
        }

        uint avgMark = toalMarksObtainedOnAllSubjects / SUBJECT_COUNT;
        if (avgMark >= 80) {
            _studentToGrade[student] = Grade.A;
        } else if (avgMark > 50 && avgMark < 80) {
            _studentToGrade[student] = Grade.B;
        } else {
            _studentToGrade[student] = Grade.C;
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