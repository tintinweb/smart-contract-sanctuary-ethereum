/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract StudentErrors {
    error NotTeacher();

    error ScoreTooHigh();
}

interface IStudent {
    function score() external view returns (uint256);

    function teacher() external view returns (address);

    function setScore(uint256 _score) external;
}

contract Student is IStudent, StudentErrors {
    uint256 public score;
    address public teacher;

    constructor(address _teacher) {
        teacher = _teacher;
    }

    modifier onlyTeacher() {
        if (msg.sender != teacher) {
            revert NotTeacher();
        }
        _;
    }

    function setScore(uint256 _score) public onlyTeacher {
        if (_score > 100) {
            revert ScoreTooHigh();
        }
        score = _score;
    }
}