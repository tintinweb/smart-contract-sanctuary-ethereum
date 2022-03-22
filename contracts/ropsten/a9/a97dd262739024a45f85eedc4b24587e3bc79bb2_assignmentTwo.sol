/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        uint t0 = gasleft();
        studentNumber = _studentNumber;
        setGasUsed(t0 - gasleft());
        
    }
    function setGasUsed(uint _difference) private {
        GasUsed = _difference;
    }
}