/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract School {

    struct Class{
        string  teachName;
        mapping(string => uint)  studentsScore;
    }
    mapping(string => Class) classes;

    function addClass(string calldata className, string calldata teachName) public {
        Class storage currClass = classes[className];
        currClass.teachName = teachName;
    }

    function addStudentScore(string calldata className,string calldata studentName,uint score) public{
        Class storage currClass = classes[className];
        currClass.studentsScore[studentName] = score;
    }

    function getStudentScoree(string calldata className,string calldata studentName) public view returns (uint){
        Class storage currClass = classes[className];
        return currClass.studentsScore[studentName];
    }
}