/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.4.24;
contract assignmentTwo {
uint public studentNumber;
uint public GasUsed;
address public student;
constructor() public {
student = msg.sender;
}

function GasUsed (uint g) public {
GasUsed=g;
}

function setStudentNumber(uint _studentNumber) public {
studentNumber = _studentNumber;
}
}