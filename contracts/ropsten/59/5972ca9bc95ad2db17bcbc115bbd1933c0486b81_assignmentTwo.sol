/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed; //1. New public uint Variable for GasUsed
    
    constructor() public {
        student = msg.sender; //stores address of first one to run this
    }
    
    //gasleft method used to get the gas used and calculate the gas used at the end
    function setStudentNumber(uint _studentNumber) public { //asks for student number
        uint initialgas = gasleft();
        studentNumber = _studentNumber;
        setGasUsed(initialgas - gasleft());
    }

    function setGasUsed(uint _GasUsed) public { //2. New setter function to ask for the gas used in step 3
        GasUsed = _GasUsed;

    }
       
}