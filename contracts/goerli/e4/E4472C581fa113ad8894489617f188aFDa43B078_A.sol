/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
	struct Student {
		uint no;
		string name;
		uint score;
	}

	Student[] public students;

	function addStudent(string memory name, uint score) public {
		students.push(Student(students.length + 1, name, score));
	}

	function getStudentLength() public view returns(uint) {
		return students.length;
	}
}