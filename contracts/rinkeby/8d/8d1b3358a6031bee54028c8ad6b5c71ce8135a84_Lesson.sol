/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract Lesson{
    
    address public senderAddress;
    uint public blockNumber;
    
    function search() public payable{
        senderAddress = msg.sender;
        blockNumber = block.number;
    }
    
}