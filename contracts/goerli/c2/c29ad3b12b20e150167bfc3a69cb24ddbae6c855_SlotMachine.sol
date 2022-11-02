/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SlotMachine {
    mapping(address => bool) public winners;

    function spin(uint guess) public {
        uint randomNumber = uint(
            keccak256(abi.encodePacked(block.timestamp, block.coinbase, block.gaslimit))
        );
        if (guess  == randomNumber) {
            winners[msg.sender] = true;
        }
    }
}