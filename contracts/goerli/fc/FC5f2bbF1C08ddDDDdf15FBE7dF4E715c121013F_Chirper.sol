/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Chirper {
    // The blocks in which an address posted a message
    mapping (address => uint[]) MessageBlocks;

    function post(string calldata _message) external {
        // We don't need to do anything with the message, we just need it here
        // so it becomes part of the transaction.
        (_message);
        require(msg.sender == tx.origin, "Only works when called directly");

        // Only add the block number if we don't already a post in this
        // block
        uint length = MessageBlocks[msg.sender].length;
        if (length == 0) {
            MessageBlocks[msg.sender].push(block.number);
        } else if (MessageBlocks[msg.sender][length-1] < block.number) {
            MessageBlocks[msg.sender].push(block.number);
        }

    }   // function post

    function getSenderMessages(address sender) public view 
        returns (uint[] memory) {
        return MessageBlocks[sender];
    }   // function getSenderMessages

}   // contract Chirper