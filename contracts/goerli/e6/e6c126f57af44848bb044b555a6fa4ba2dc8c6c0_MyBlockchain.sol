/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract MyBlockchain  {
    uint public Number;
    
    event NewNumber (uint Number, uint _newNumber);

    function addNumber (uint _newNumber) external payable {
        uint oldNumber = Number;
        Number = _newNumber ;
        emit NewNumber (oldNumber, Number);
        
    }
       
}