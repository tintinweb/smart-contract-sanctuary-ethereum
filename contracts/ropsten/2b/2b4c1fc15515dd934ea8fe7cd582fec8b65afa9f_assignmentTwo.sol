/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.24;
contract assignmentTwo {
    uint public studentNumber;
    address public student;
    uint public GasUsed;

constructor() public {
    student = msg.sender;
    }
        function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
        }
        function GasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
        }
    }