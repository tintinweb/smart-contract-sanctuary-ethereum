// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error StudentService__NotEnoughETHEntered();
error StudentService__ExamAlreadyGraded();
error StudentService__UserNotAuthorised();
error StudentService__ExamAlreadyRegistered();

contract StudentService {
    /* Type declarations */

    /* Enums */
    enum UserRole {
        STUDENT,
        PROFESSOR
    }

    /* Structs */
    struct ExamResult {
        address student;
        Exam exam;
        uint256 grade;
    }
    struct Course {
        string name;
        address professor;
    }
    struct Exam {
        uint256 id;
        Course course;
        uint256 examDate;
    }
    struct User {
        string fullName;
        string email;
        UserRole role;
    }

    /* Variables */
    uint256 private constant EXAM_FEE = 1e9;
    mapping(address => User) private users;
    Exam[] private exams;
    ExamResult[] private examHistory;

    /* Functions */
    constructor() {
        loadData();
    }

    function loadData() private {
        users[0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4] = User(
            "Petar Markovic",
            "[email protected]",
            UserRole.STUDENT
        );
        users[0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5] = User(
            "Goran Sladic",
            "[email protected]",
            UserRole.PROFESSOR
        );
        users[0xdf26F670674fbF1f5BD3c60f67299e33ec68c659] = User(
            "Minja Vidakovic",
            "[email protected]",
            UserRole.PROFESSOR
        );
        Course memory course0 = Course(
            "Objektno orijentisano programiranje",
            0xdf26F670674fbF1f5BD3c60f67299e33ec68c659
        );
        Course memory course1 = Course(
            "Bezbednost u elektronskom poslovanju",
            0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5
        );
        Course memory course2 = Course(
            "Internet softverska arhitektura",
            0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5
        );
        Exam memory exam0 = Exam(0, course0, 1659045968);
        Exam memory exam1 = Exam(1, course1, 1659023168);
        Exam memory exam2 = Exam(2, course2, 1659063168);
        Exam memory exam5 = Exam(2, course2, 1659063168);

        exams.push(exam0);
        exams.push(exam1);
        exams.push(exam2);
        examHistory.push(
            ExamResult(0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4, exams[0], 6)
        );
        examHistory.push(
            ExamResult(0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4, exams[1], 6)
        );
        examHistory.push(
            ExamResult(0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4, exams[2], 8)
        );
    }

    function registerExam(uint256 _examId) public payable {
        if (getUser(msg.sender).role != UserRole.STUDENT) {
            revert StudentService__UserNotAuthorised();
        }
        if (msg.value < EXAM_FEE) {
            revert StudentService__NotEnoughETHEntered();
        }
        if (examRegistered(_examId, msg.sender) == true) {
            revert StudentService__ExamAlreadyRegistered();
        }
        examHistory.push(ExamResult(msg.sender, exams[_examId], 0));
    }

    function gradeExam(
        uint256 _examId,
        address _student,
        uint256 _grade
    ) public {
        if (getUser(msg.sender).role != UserRole.PROFESSOR) {
            revert StudentService__UserNotAuthorised();
        }
        for (uint i = 0; i < examHistory.length; i++) {
            if (
                examHistory[i].exam.id == _examId &&
                examHistory[i].student == _student
            ) {
                if (examHistory[i].grade != 0) {
                    revert StudentService__ExamAlreadyGraded();
                }
                examHistory[i].grade = _grade;
                break;
            }
        }
    }

    /** Getter Functions */
    function getExamFee() public pure returns (uint256) {
        return EXAM_FEE;
    }

    function getUser(address _address) public view returns (User memory) {
        return users[_address];
    }

    function getUserRole(address _address) public view returns (UserRole) {
        return users[_address].role;
    }

    function getExamsForUser(address _address)
        public
        view
        returns (ExamResult[] memory, uint256 endIndex)
    {
        ExamResult[] memory _examHistory = new ExamResult[](examHistory.length);
        uint256 index = 0;
        for (uint256 i = 0; i < examHistory.length; i++) {
            if (examHistory[i].student == _address) {
                _examHistory[index] = examHistory[i];
                index += 1;
            } else if (examHistory[i].exam.course.professor == _address) {
                _examHistory[index] = examHistory[i];
                index += 1;
            }
        }

        return (_examHistory, index);
    }

    function getExams() public view returns (Exam[] memory) {
        return exams;
    }

    function examRegistered(uint256 id, address student)
        public
        view
        returns (bool)
    {
        for (uint i = 0; i < examHistory.length; i++) {
            if (
                examHistory[i].exam.id == id &&
                examHistory[i].student == student
            ) {
                return true;
            }
        }
        return false;
    }
}