/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;     // ^ means complier ver. can starting from 0.8.1 but less than 0.9 same as '>=0.8.1 < 0.9.0'
contract Greetings {        // 'contract' is like 'class'
    string public message;  // make sure you storing only important data, 'public' mean it can be call outsite from your smartcontract
    constructor(string memory _initialMessage) {        // constructor is special function, that will be call automatically when you deploy smartcontract but it will be call only one
        
        message = _initialMessage; 
    } 
    function setMessage(string memory _newMessage) public {     // another function that will change the value of variable; we have to write the function ourself, solidity will only create read function for you
        message = _newMessage; 
    }
}