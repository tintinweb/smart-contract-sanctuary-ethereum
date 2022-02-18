/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

contract QuyLop {
    struct Student {
        address wallet;
        string name;
        uint amount;
    }

    Student[] private students;
    address private owner;

    event depositHasBeenUpdate(address wallet, string name, uint amount);

    constructor(){
        owner = msg.sender;
    }

    function deposit(string memory name) public payable {
        require(msg.value >= 1000000000000000, "Amount must be greater than 0.001 ETH");
        Student memory newStudent = Student(msg.sender, name, msg.value);
        students.push(newStudent);
        emit depositHasBeenUpdate(newStudent.wallet, newStudent.name, newStudent.amount);
    }

    function withdraw() public {
        require(msg.sender == owner, "Not authoried !");
        require(address(this).balance>0, "Has no money in wallet !!!");
        payable(owner).transfer(address(this).balance);
    }

    function countStudent() public view returns(uint) {
        return students.length;
    }

    function showTotalAmount() public view returns(uint) {
        return address(this).balance;
    }

    function getStudentInfo(uint index) public view returns(address, string memory, uint){
        uint studentCnt = students.length;
        require(studentCnt > 0, "Students array is empty !");
        require(index < studentCnt, "This student is not exists !");
        Student memory student = students[index];
        return (student.wallet, student.name, student.amount);
    }


}