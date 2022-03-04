/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IScore {
    function setStudentScore(address _addr, uint256 _score) external;
}

contract Teacher {
    //学生合约地址
    IScore public score;

    constructor(IScore _scoreAddr) {
        score = _scoreAddr;
    }

    //老师修改学生分数
    function teacherSetStudentScore(address _addr, uint256 _score) public {
        score.setStudentScore(_addr, _score);
    }
}