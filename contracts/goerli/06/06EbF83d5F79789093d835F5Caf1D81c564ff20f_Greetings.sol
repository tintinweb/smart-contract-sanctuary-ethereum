/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: GPL-3.0

// for what solidity compiler version 0.8.1 - 0.8.9
pragma solidity ^0.8.1;

// declare contract
contract Greetings { 
    // anyone can access but only read! solidity generate only getter func name according variable name
    string public message; // can change value but tx is recorded
    // called when deploy smart contract
    constructor(string memory _initialMessage) {
        
        message = _initialMessage; 
    } 

    // anyone can call
    function setMessage(string memory _newMessage) public {
        message = _newMessage; 
    }
}