/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Payment {

    struct Semester {
        uint256 amount;
        uint256 start;
        string batch;
        uint256 semester;
    }

    mapping(string => mapping(uint256 => Semester)) public semesters;

    struct Student {
        address addr;
        string name;
        string rollNo;
        string batch;
        uint256 semester;
        uint256 amount;
        uint256 date;
    }

    Student[] public students;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addSemester(
        string memory _batch,
        uint256 _semester
        
    ) external onlyOwner payable {
        semesters[_batch][_semester] = Semester(
            msg.value,
            block.timestamp,
            _batch,
            _semester
        );
    }

    function pay(
        string memory _name,
        string memory _rollNo,
        string memory _batch,
        uint256 _semester
    ) external payable {
        require(msg.value > 0, "amount can't be less than zero");
        uint256 semester = semesters[_batch][_semester].semester;
        string memory batch = semesters[_batch][_semester].batch;
        uint amount = semesters[_batch][_semester].amount;
        require(msg.value >= amount, "amount can't be less");
        require(semester == _semester, "semester not exit");
        require(
            keccak256(abi.encodePacked(batch)) ==
                keccak256(abi.encodePacked(_batch)),
            "batch not exist"
        );
        students.push(
            Student(
                msg.sender,
                _name,
                _rollNo,
                _batch,
                _semester,
                msg.value,
                block.timestamp
            )
        );
    }

    function getStudents() external view returns (Student[] memory) {
        return students;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
}