/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RandomNumber{

    uint number;

    function get_random() public{
        bytes32 ramdon = keccak256(abi.encodePacked(block.timestamp,blockhash(block.number-1)));
        number = uint(ramdon);
    }
    
    constructor (){}
}