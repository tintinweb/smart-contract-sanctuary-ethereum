/**
 *Submitted for verification at Etherscan.io on 2022-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IScore {
    function setStudentScore(address _addr, uint256 _score) external;
}

contract Teacher {
    IScore public score;

    constructor(IScore _scoreAddr) {
        score = _scoreAddr;
    }

    function modifyStudentScore(address _addr, uint256 _score) public {
        score.setStudentScore(_addr, _score);
    }
}