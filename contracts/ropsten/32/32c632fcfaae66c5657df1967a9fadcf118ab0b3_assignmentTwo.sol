/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed; //1. New public uint Variable for GasUsed
    
    constructor() public {
        student = msg.sender; //stores address of first one to run this
    }
    
    function setStudentNumber(uint _studentNumber) public { //3. asks for student number
        studentNumber = _studentNumber;
    }

    function setGasUsed(uint _GasUsed) public { //2. New setter function to ask for the gas used in step 3
        require(msg.sender==student); //requires that the owner of the contract is the only one who can set the gas used
        GasUsed = _GasUsed; //4. ask for the gas used

    }
       
}