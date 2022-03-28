/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity ^0.4.22;

contract test3 {
    
    uint public studentNumber;
    uint public gasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        uint256 initGas = gasleft();
        studentNumber = _studentNumber;
        setGasUsed(initGas-gasleft());
    }
 
    function setGasUsed(uint _gasUsed) public{
        gasUsed = _gasUsed;
    }
       
}