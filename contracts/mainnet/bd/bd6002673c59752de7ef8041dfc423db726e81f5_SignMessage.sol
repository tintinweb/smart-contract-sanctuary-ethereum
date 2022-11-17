/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract SignMessage {
    event SignedMessage(address signer, string message, uint blockNumber, uint timestamp);
    function sign(string memory message) public{
        emit SignedMessage(msg.sender, message, block.number, block.timestamp);
    }
}