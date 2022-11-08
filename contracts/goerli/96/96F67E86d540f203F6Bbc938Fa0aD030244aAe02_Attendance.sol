// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Attendance{

    mapping(address=>bool) attendance;
    address[] public students;


    function present(address student) public {
        attendance[student] = true;
        students.push(student);

    }

    function studentsInAttendance() public view returns(uint){
        return students.length;
    }

    function isPresent(address student) public view returns(bool) {
        return attendance[student];
    }
    
}