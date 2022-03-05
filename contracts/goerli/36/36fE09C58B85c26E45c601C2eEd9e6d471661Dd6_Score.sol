/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Score {
    mapping(address => uint256) public student;
    mapping(address => bool) public teacherAddr;

    address ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }


    modifier onlyTeacher() {
        require(teacherAddr[tx.origin], "no authority");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender==ownerAddress, "only owner");
        _;
    }

    function setStudentScore(address _addr, uint256 _score) public onlyTeacher {
        require(_score <= 100, "score cannot be less than 100");
        student[_addr] = _score;
    }

    function addTeacher(address _addr) public onlyOwner {
        teacherAddr[_addr] = true;
    }
}