/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; 
contract MyContract{ 
    string message = "Hello Ethereum"; 
function setMessage(string memory _message) public{ 
    message=_message; 
    } 
function getMessage() public view returns (string memory) { 
    return message; 
    }
}