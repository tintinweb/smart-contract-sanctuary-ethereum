/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    uint public startGas;
    uint public txnGas;
    
    constructor() {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        startGas = gasleft();            
        studentNumber = _studentNumber;
        txnGas = gasleft();
        GasUsed = startGas - txnGas;
        setGasUsed(GasUsed);
    }

    function setGasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }     
}