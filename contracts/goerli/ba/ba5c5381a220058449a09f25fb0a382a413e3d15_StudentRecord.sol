/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract StudentRecord {
    struct student {
        uint Number;
        string Name;
        uint Math;
        string Class;
    }
    student[] private Students;

    function addStudent(uint _number,string memory _name, uint _math) public returns(student[] memory){
        Students.push(student(_number,_name, _math, "none"));
        return Students;
    }

    function classAssign() public returns(student[] memory) {
        string memory newClass;
        for(uint i = 0; i < Students.length;i++){
            if(Students[i].Math >= 90){
                newClass = "A";
                _replaceGrade(i, newClass);
            } else if(Students[i].Math >= 80 && Students[i].Math < 90){
                newClass = "B";
                _replaceGrade(i, newClass);
            } else if(Students[i].Math >= 70 && Students[i].Math < 80){
                newClass = "C";
                _replaceGrade(i, newClass);
            } else if(Students[i].Math < 70){
                newClass = "D";
                _replaceGrade(i, newClass);
            }
        }
        return Students;
      
    }
    function _replaceGrade(uint _index, string memory _newClass) private {
        student memory oldinfo = Students[_index];
        delete Students[_index]; 
        Students[_index] = student(oldinfo.Number, oldinfo.Name,  oldinfo.Math, _newClass );   
    }
    // 점수 수정
    function modifyScore(uint _index,  uint _math) public returns(student memory){
        student memory oldinfo = Students[_index -1];
        delete Students[_index -1]; 
        Students[_index -1] = student(oldinfo.Number, oldinfo.Name, _math, oldinfo.Class );
        return Students[_index -1];    
    }

    function showAll() public view returns(student[] memory){
        return Students;
    }

    function showStudent(uint _index) public view returns(student memory){
        return Students[_index -1];
    }
}