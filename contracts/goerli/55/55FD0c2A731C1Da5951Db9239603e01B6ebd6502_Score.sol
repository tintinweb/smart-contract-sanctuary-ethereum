// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Score {
    error NotTeacher();
    error InvalidScore();

    address public teacherAddress;
    mapping(address => uint) scores;

    constructor(address teacherAddress_){
        teacherAddress = teacherAddress_;
    }

    modifier onlyTeacher{
        if (msg.sender != teacherAddress) revert NotTeacher();
        _;
    }

    function setScore(address studentAddress, uint score) external onlyTeacher {
        if (score > 100) revert InvalidScore();
        scores[studentAddress] = score;
    }

    function getScore(address studentAddress) external view returns (uint){
        return scores[studentAddress];
    }
}