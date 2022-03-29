/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
    constructor() public {
        student = msg.sender;
    }

    function setTransactionGasUsed(uint _transactionGasUsed) public {
        GasUsed = _transactionGasUsed;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
       
}