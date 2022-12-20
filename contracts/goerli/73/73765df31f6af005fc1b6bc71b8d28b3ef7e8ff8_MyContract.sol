/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MyContract{
    event MyEvent(uint indexed id, uint indexed date, string value);
    
    uint nextId;

    function emitEvent(string calldata value) external {
        emit MyEvent(nextId,block.timestamp,value);
        nextId++;
    }
}