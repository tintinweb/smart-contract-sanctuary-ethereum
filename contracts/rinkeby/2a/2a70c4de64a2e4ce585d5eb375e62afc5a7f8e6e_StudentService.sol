// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/* Contract */
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
        string studentName;
        Exam exam;
        uint256 grade;
    }
    struct Course {
        string name;
        address professor;
        string professorName;
    }
    struct Exam {
        uint256 id;
        Course course;
        uint examDate;
        bool exists;
    }
    struct User {
        string fullName;
        string email;
        UserRole role;
        bool exists;
    }

    /* Variables */
    uint256 private constant EXAM_FEE = 0.001 ether;
    mapping(address => User) private users;
    Exam[] private exams;
    mapping(address => ExamResult[]) private studentExamResults;
    mapping(address => ExamResult[]) private professorExamResults;

    /* Events */
    event examRegistered(address indexed student, uint256 indexed examId);
    event examGraded(
        address indexed student,
        uint256 indexed examId,
        uint256 indexed grade
    );

    /* Modifiers */
    modifier userExists(address _address) {
        if (getUser(_address).exists != true)
            revert("Student not registered in student service");
        _;
    }
    modifier examExists(uint256 _index) {
        if (getExam(_index).exists != true) revert("Exam does not exist");
        _;
    }
    modifier userAuthorised(address _address, UserRole _role) {
        if (getUser(_address).role != _role) revert("User not authorised");
        _;
    }
    modifier sufficientETH(uint _value) {
        if (_value < EXAM_FEE) revert("Insufficient funds entered");
        _;
    }
    modifier examRegisteredLate(uint _index) {
        if (getExam(_index).examDate - block.timestamp < 172800)
            revert("Exam must be registered at least 2 days before");
        _;
    }
    modifier examHistoryExists(uint256 _index, address _address) {
        if (examIsRegistered(_index, _address) == true)
            revert("Exam already registered");
        _;
    }

    /* Constructor */
    constructor() {
        loadData();
    }

    /* Functions */

    /* Helper functions */
    function loadData() private {
        users[0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4] = User(
            "Petar Markovic",
            "[email protected]",
            UserRole.STUDENT,
            true
        );
        users[0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5] = User(
            "Goran Sladic",
            "[email protected]",
            UserRole.PROFESSOR,
            true
        );
        users[0xdf26F670674fbF1f5BD3c60f67299e33ec68c659] = User(
            "Milan Vidakovic",
            "[email protected]",
            UserRole.PROFESSOR,
            true
        );
        Course memory course0 = Course(
            "Objektno orijentisano programiranje",
            0xdf26F670674fbF1f5BD3c60f67299e33ec68c659,
            "Milan Vidakovic"
        );
        Course memory course1 = Course(
            "Bezbednost u elektronskom poslovanju",
            0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5,
            "Goran Sladic"
        );
        Course memory course2 = Course(
            "Internet softverska arhitektura",
            0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5,
            "Goran Sladic"
        );
        Course memory course3 = Course(
            "Algoritmi i strukture podataka",
            0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5,
            "Goran Sladic"
        );
        Course memory course4 = Course(
            "Veb programiranje",
            0xdf26F670674fbF1f5BD3c60f67299e33ec68c659,
            "Milan Vidakovic"
        );

        Exam memory exam0 = Exam(0, course0, 1664335957, true);
        Exam memory exam1 = Exam(1, course1, 1664335534, true);
        Exam memory exam2 = Exam(2, course2, 1664336421, true);
        Exam memory exam3 = Exam(3, course3, 1664336721, true);
        Exam memory exam4 = Exam(4, course4, 1664336916, true);

        exams.push(exam0);
        exams.push(exam1);
        exams.push(exam2);
        exams.push(exam3);
        exams.push(exam4);

        studentExamResults[0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4].push(
            ExamResult(
                0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4,
                "Petar Markovic",
                exams[1],
                7
            )
        );
        professorExamResults[0xf61D8b5E25c0C69012e225ef7c1102B1451D43e5].push(
            ExamResult(
                0xA5A5A6c6C867e8BFd6cF8fcF472D70bC53eCb7a4,
                "Petar Markovic",
                exams[1],
                7
            )
        );
    }

    function examIsRegistered(uint256 _index, address _address)
        public
        view
        userExists(_address)
        examExists(_index)
        returns (bool)
    //ADA
    {
        for (uint i = 0; i < studentExamResults[_address].length; i++) {
            if (
                studentExamResults[_address][i].exam.id == _index &&
                studentExamResults[_address][i].student == _address
            ) {
                return true;
            }
        }
        return false;
    }

    function gradeExam(
        uint256 _index,
        address _address,
        uint256 _grade
    )
        public
        userExists(_address)
        userExists(msg.sender)
        examExists(_index)
        userAuthorised(msg.sender, UserRole.PROFESSOR)
        examHistoryExists(_index, msg.sender)
    {
        for (uint i = 0; i < professorExamResults[msg.sender].length; i++) {
            if (
                professorExamResults[msg.sender][i].exam.id == _index &&
                professorExamResults[msg.sender][i].student == _address
            ) {
                if (professorExamResults[msg.sender][i].grade != 0) {
                    revert("Exam already graded");
                }
                professorExamResults[msg.sender][i].grade = _grade;
                for (uint j = 0; i < studentExamResults[_address].length; j++) {
                    if (
                        studentExamResults[_address][j].exam.id == _index &&
                        studentExamResults[_address][j].student == _address
                    ) {
                        studentExamResults[_address][j].grade = _grade;
                        break;
                    }
                }
                emit examGraded(_address, _index, _grade);
                break;
            }
        }
    }

    function registerExam(uint256 _index)
        public
        payable
        userExists(msg.sender)
        examExists(_index)
        userAuthorised(msg.sender, UserRole.STUDENT)
        sufficientETH(msg.value)
        examRegisteredLate(_index)
        examHistoryExists(_index, msg.sender)
    {
        studentExamResults[msg.sender].push(
            ExamResult(
                msg.sender,
                getUser(msg.sender).fullName,
                exams[_index],
                0
            )
        );
        professorExamResults[exams[_index].course.professor].push(
            ExamResult(
                msg.sender,
                getUser(msg.sender).fullName,
                exams[_index],
                0
            )
        );

        emit examRegistered(msg.sender, _index);
    }

    /* Getter functions */
    function getUser(address _address) public view returns (User memory) {
        return users[_address];
    }

    function getExam(uint256 _index) public view returns (Exam memory) {
        return exams[_index];
    }

    function getExams() public view returns (Exam[] memory) {
        return exams;
    }

    function getExamFee() public pure returns (uint256) {
        return EXAM_FEE;
    }

    function getExamResults(address _address, UserRole _role)
        public
        view
        returns (ExamResult[] memory)
    {
        if (_role == UserRole.STUDENT) {
            return studentExamResults[_address];
        }
        return professorExamResults[_address];
    }

    function getNotRegisteredExams(address _address)
        public
        view
        userExists(_address)
        userAuthorised(_address, UserRole.STUDENT)
        returns (Exam[] memory)
    {
        Exam[] memory notRegisteredExams = new Exam[](
            exams.length - studentExamResults[_address].length
        );
        uint256 index = 0;
        for (uint i = 0; i < exams.length; i++) {
            if (examIsRegistered(exams[i].id, _address) == false) {
                notRegisteredExams[index] = exams[i];
                index++;
            }
        }
        return notRegisteredExams;
    }
}