/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract studentTracker {

    uint256 public classCounter = 0;
    address owner;

    mapping (uint => address[]) teacherStudentsPerClass; // class => students array
    mapping (uint256 => mapping (address => bool)) public classTracker;

    modifier onlyTeacher() {
        require(msg.sender == owner, "You're not the teacher");
        _;
    }

    modifier onlyStudent() {
        require(msg.sender != owner, "You're not a student");
        _;
    }

    modifier notTrackedBefore(address student) {
        require(classTracker[classCounter][msg.sender] == false, "You are already tracked");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function _addClass() private {
        classCounter++;
        teacherStudentsPerClass[classCounter].push(msg.sender);
    }

    function addClass() external onlyTeacher {
        _addClass();
    }

    function removeClass() external onlyTeacher {
        teacherStudentsPerClass[classCounter] = new address[](0);
        classCounter--;
    }

    // add student to current class
    function trackStudent() external onlyStudent notTrackedBefore(msg.sender) {
        classTracker[classCounter][msg.sender] = true;
        teacherStudentsPerClass[classCounter].push(msg.sender);
    }

    // get functions
    function getStudentsPerClass(uint256 classId) public view returns(address[] memory) {
        return teacherStudentsPerClass[classId];
    }

    function getNumberStudentsPerClass(uint256 classId) public view returns(uint256) {
        return teacherStudentsPerClass[classId].length;
    }

}