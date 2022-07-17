/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PracticeSolidity{
    struct Student{
        string name;
        uint256 age;
    }

    uint256 public counter;
    event studentEvetn (string indexed _name, uint256 indexed _age);
    mapping(uint256=> Student) public students;
    Student[] public  people;

    function setNewStudent(string memory _name , uint256 _age) public {
        // require(_name == 'null',"Please Enter student Name!");
        Student memory newStd = Student(_name,_age);
        students[counter] = newStd;
        people.push(Student(_name,_age));
        counter++;
        emit studentEvetn(_name,_age);
    }
}