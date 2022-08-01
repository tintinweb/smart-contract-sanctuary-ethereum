/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract School {
    
    struct Class {
        string teacher;
        mapping(string => uint) scores;
    }
    
    mapping(string => Class) classes;
    
    function addClass(string calldata className, string calldata teacher) public {
        // 錯誤寫法：classes[className] = Class(teacher);
        // (classes[className]).teacher = teacher; 等價於下面兩行
        Class storage class = classes[className];
        class.teacher = teacher;
    }
    
    function addStudentScore(string calldata className, string calldata studentName, uint score) public {
        // (classes[className]).scores[studentName] = score; 等價於下面兩行
        Class storage class = classes[className];
        class.scores[studentName] = score;
    }
    
    function getStudentScore(string calldata className, string calldata studentName) public view returns (uint) { 
        // return (classes[className]).scores[studentName]; 等價於下面兩行
        Class storage class = classes[className];
        return class.scores[studentName];
    }
}