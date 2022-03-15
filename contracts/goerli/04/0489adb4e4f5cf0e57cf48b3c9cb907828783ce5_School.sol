/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract School{
    struct Class {
        string teacher;
        mapping(string=>uint)scores; 
    }

    mapping (string=>Class)classes;

    function addClass(string calldata className,string calldata teacher)public{
        Class storage class = classes[className];
        class.teacher = teacher;
    }

    function addSocker(string calldata className ,string calldata studentName,uint score)public{
        (classes[className]).scores[studentName]=score;
      
        Class storage class = classes[className];
        class.scores[studentName] = score;
    }

    function getStudentScore(string calldata className ,string calldata studentName) public view returns (uint){
        return (classes[className]).scores[studentName];
    }

}