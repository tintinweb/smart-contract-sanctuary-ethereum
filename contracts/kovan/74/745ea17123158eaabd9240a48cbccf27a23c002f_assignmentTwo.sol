/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
    constructor() {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        uint256 startGas = gasleft();
        studentNumber = _studentNumber;
        GasUsed = startGas - gasleft();
        setGasUsed(GasUsed);
    }

    function setGasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
       
}