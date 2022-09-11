/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract message {
    
    mapping(address => string) public messages;

    function saveMessage(string memory _message) external {
        messages[msg.sender] = _message;
    }

}