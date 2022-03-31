/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.4.24; // it shows which compilar is used

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public gasUsed;
    
    constructor() public {  
        student = msg.sender;
    }
    
    function setGasUsed(uint _gasUsed) public{
        gasUsed = _gasUsed;
    }

    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
       
}