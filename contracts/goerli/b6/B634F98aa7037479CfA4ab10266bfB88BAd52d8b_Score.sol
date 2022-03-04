/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Score {
    //学生数据
    mapping(address => uint256) public student;
    //多老师地址
    mapping(address => bool) public teacherAddr;

    event AddTeacher(
        address indexed sender,
        address indexed newTeacher,
        uint256 time
    );

    event StudentScore(
        address indexed teacherAddr,
        address indexed studentAddr,
        uint256 score,
        uint256 time
    );

    modifier onlyTeacher() {
        require(teacherAddr[msg.sender], "no authority");
        _;
    }

    constructor() {
        teacherAddr[msg.sender] = true;
    }

    //修改学生分数
    function setStudentScore(address _addr, uint256 _score) public onlyTeacher {
        require(_score <= 100, "score cannot be less than 100");
        student[_addr] = _score;
        emit StudentScore(msg.sender, _addr, _score, block.timestamp);
    }

    //新增老师
    function addTeacher(address _addr) public onlyTeacher {
        teacherAddr[_addr] = true;
        emit AddTeacher(msg.sender, _addr, block.timestamp);
    }
}