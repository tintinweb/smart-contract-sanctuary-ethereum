// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

contract StudentVerify {
    struct studentData {
        uint256 rollNo;
        string name;
        uint256 totalMarks;
        string[] reasons;
    }
    mapping(uint256 => studentData) public allStudentData;
    address _owner;
    address _examiner;

    constructor() {
        _owner = msg.sender;
    }

    function setExaminer(address examiner) public onlyOwner {
        _examiner = examiner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call.");
        _;
    }

    modifier onlyExaminer() {
        require(msg.sender == _examiner, "Only examiner can call.");
        _;
    }

    function setStudentName(
        uint256 _rollNo,
        string memory name
    ) public onlyOwner {
        allStudentData[_rollNo].name = name;
    }

    function getStudentData(
        uint256 _rollNo
    ) public view onlyOwner returns (studentData memory) {
        return allStudentData[_rollNo];
    }

    function addExaminerMarks(
        uint256 _rollNo,
        uint256 _examinerMarks
    ) public onlyExaminer {
        allStudentData[_rollNo].totalMarks = _examinerMarks;
    }

    function addScrutinizerMarks(
        uint256 _rollNo,
        uint256 _scrutinizerMarks,
        string memory _reason
    ) public onlyOwner {
        require(
            _scrutinizerMarks >= 0,
            "Scrutinizer marks must be non-negative"
        );
        if (allStudentData[_rollNo].totalMarks != _scrutinizerMarks) {
            require(bytes(_reason).length != 0, "Give a reason");
            allStudentData[_rollNo].reasons.push(
                string.concat("SCRUTINZER_", _reason)
            );
            allStudentData[_rollNo].totalMarks = _scrutinizerMarks;
        }
    }

    function getReasons(
        uint256 rollNo
    ) public view onlyOwner returns (string[] memory) {
        return allStudentData[rollNo].reasons;
    }

    function addHeadMarks(
        uint256 rollNo,
        uint256 headMarks,
        string memory reason
    ) public onlyOwner {
        if (allStudentData[rollNo].totalMarks != headMarks) {
            require(bytes(reason).length != 0, "Give a reason");
            allStudentData[rollNo].reasons.push(string.concat("HEAD_", reason));
            allStudentData[rollNo].totalMarks = headMarks;
        }
    }

    function addTabMarks(
        uint256 rollNo,
        uint256 tabMarks,
        string memory reason
    ) public onlyOwner {
        if (allStudentData[rollNo].totalMarks != tabMarks) {
            require(bytes(reason).length != 0, "Give a reason");
            allStudentData[rollNo].reasons.push(string.concat("TAB_", reason));
            allStudentData[rollNo].totalMarks = tabMarks;
        }
    }

    function addCouncilorMarks(
        uint256 rollNo,
        uint256 councilorMarks,
        string memory reason
    ) public onlyOwner {
        if (allStudentData[rollNo].totalMarks != councilorMarks) {
            require(bytes(reason).length != 0, "Give a reason");
            allStudentData[rollNo].reasons.push(
                string.concat("COUNCILOR_", reason)
            );
            allStudentData[rollNo].totalMarks = councilorMarks;
        }
    }
}