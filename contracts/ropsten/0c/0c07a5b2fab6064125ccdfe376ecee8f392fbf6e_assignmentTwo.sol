/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.4.22;

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
     function setGasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
       
}