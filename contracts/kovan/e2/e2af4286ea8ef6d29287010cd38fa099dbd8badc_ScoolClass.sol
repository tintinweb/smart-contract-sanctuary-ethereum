/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

contract ScoolClass{
    struct Class{
        string teacher;
        mapping(string=>uint) _scores;
    }
    mapping(string=>Class) _classes;

    function addClass(string memory className,string memory teacher) public{
        Class storage class=_classes[className];
        class.teacher=teacher;
    }

    function addScores(string memory className,string memory student,uint score)public{
        Class storage class=_classes[className];
        class._scores[student]=score;
    }
    function getStudentScore(string memory className,string memory student)public view returns(uint){
        Class storage class=_classes[className];
        return class._scores[student];
    }

}