/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// File: contracts/Asistencia.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Asistencia {
    uint256 public lessonCounter;
    address owner;
    mapping (uint256 => uint256) public assistanceCount;
    mapping (uint256 => mapping (address => bool)) public lessonTracker;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the teacher");
        _;
    }

    function addLesson() external isOwner {
        lessonCounter++;
    }

    function removeLesson() external isOwner {
        _removeLesson();
    }

    function _removeLesson() private {
        lessonCounter--;
    }

    function addStudent() external {
        require(lessonTracker[lessonCounter][msg.sender] == false, "You already signed up");
        lessonTracker[lessonCounter][msg.sender] = true;
        assistanceCount[lessonCounter]++;
    }

    function countStudents(uint256 lessonId) external view returns (uint256) {
        return assistanceCount[lessonId];
    }
}