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

contract B {
	A a;

	A.Student[] topStudents;
	mapping(uint => A.Student) topStudentByNo;
	mapping(string => A.Student) topStudentByName;

	constructor(address a_address) {
		a = A(a_address);
	}

	function clearTopStudents() private {
		for(uint i = 0; i < topStudents.length; i++) {
			delete topStudentByNo[topStudents[i].no];
			delete topStudentByName[topStudents[i].name];
		}
	}

	function collect() public {
		clearTopStudents();
		
		uint no;
		string memory name;
		uint score;
		for(uint i = 0; i < a.getStudentLength(); i++) {
			(no, name, score) = a.students(i);
			if(score >= 80) {
				A.Student memory student = A.Student(no, name, score);
				topStudents.push(student);
				topStudentByNo[no] = student;
				topStudentByName[name] = student;
			}
		}
	}

	function findByNo(uint no) public view returns(A.Student memory) {
		return topStudentByNo[no];
	}

	function findByName(string memory name) public view returns(A.Student memory) {
		return topStudentByName[name];
	}
}