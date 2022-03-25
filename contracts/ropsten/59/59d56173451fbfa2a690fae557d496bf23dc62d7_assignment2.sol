/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.4.22;

contract assignment2 {
    uint public studentNumber;
    address public student;
    uint public GasUsed;

    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }

    function setter(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
}