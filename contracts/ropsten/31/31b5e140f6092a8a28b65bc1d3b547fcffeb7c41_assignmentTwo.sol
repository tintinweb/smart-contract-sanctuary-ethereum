/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint256 public gasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender; 
    }
    function setStudentNumber(uint _studentNumber) public payable{        
        studentNumber = _studentNumber;                   
    }
    function setGasUsed(uint256 _gasUsed) public {
        gasUsed = _gasUsed;
       
    }       
}