/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyBlockchain {
    uint public Number = 0;
    
    
    function addNumber(uint _newNumber) public {
        Number = _newNumber;
    }
}