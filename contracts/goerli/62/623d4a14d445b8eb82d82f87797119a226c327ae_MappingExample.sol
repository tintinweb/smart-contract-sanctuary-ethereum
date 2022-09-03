/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// 學生成績表
// 學生名字 (string) 與成績(uint)
// 要用名字來查詢成績
// 能夠清除所有已經輸入過的成績
// 放榜

contract MappingExample {
    mapping(string => uint) public scoreTable; // 學生名字對應成績
    string[] studentList;

    event getScoreResult(string _result);

    function addScore(string memory name, uint score) public {
        scoreTable[name] = score;
        studentList.push(name);
    }

    function getScore(string memory name) public returns (uint) {
        uint score = scoreTable[name];
        emit getScoreResult(score > 60 ? "PASS" : "FAILED");
        return score;
    }

    function clear() public {
        while (studentList.length > 0) {
            uint isLastStudent = studentList.length - 1;
            delete scoreTable[studentList[isLastStudent]];
            studentList.pop();
        }
    }
}