// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;
interface IScore {
    function setScore(
        address studentAddress,
        uint256 studentScore
    ) external returns (bool);
    function getStudentScore(address studentAddress) external view returns (uint256);
}

contract Score {
    event ScoreSet(address indexed studentAddress, uint256 studentScore);
    error NotOwner();
    error NotTeacher();
    error ScoreNotThan100();
    mapping(address => uint256) public students;
    address teacher;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function setTeacher(address teacherAddress) public {
        if (owner == msg.sender) {
            teacher = teacherAddress;
        } else {
            revert NotOwner();
        }
    }

    modifier onlyTeacher() {
        if (teacher != msg.sender) {
            revert NotTeacher();
        }
        _;
    }

    function setScore(
        address studentAddress,
        uint256 studentScore
    ) external  onlyTeacher returns (bool) {
        if (studentScore > 100) {
            revert ScoreNotThan100();
        }
        students[studentAddress] = studentScore;
        emit ScoreSet(studentAddress, studentScore);
        return true;
    }

    function getStudentScore(address studentAddress) external view returns (uint256) {
        return students[studentAddress];
    }
}
contract Teacher {
    IScore score;

    constructor(address scoreAddress) {
        score = IScore(scoreAddress);
    }

    function setStudentScores(
        address studentAddress,
        uint256 studentScore
    ) external returns (bool) {
    
         score.setScore(studentAddress, studentScore);
         return true;
    }
    function getStudentScore(address studentAddress) external view returns (uint256) {
        return score.getStudentScore(studentAddress);
    }
}