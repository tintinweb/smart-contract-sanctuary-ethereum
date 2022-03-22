/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.4.24;
contract assignmentTwo {
uint public studentNumber;
uint public GasUsed;
address public student;
constructor() public {
student = msg.sender;
}
function setStudentNumber(uint _studentNumber) public {
studentNumber = _studentNumber;
}
function setGasFee(uint _GasUsed) public {
GasUsed = _GasUsed;
}
}