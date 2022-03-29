/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.22;

contract assignmentTwo{
    
    address public student;
    uint public studentNumber;
    uint public gasUsed;

    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
 
    function setGasUsed(uint _gasUsed) public{
        gasUsed = _gasUsed;
    }
       
}