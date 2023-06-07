/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

interface ITransmitter {
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody
    ) external returns (uint64);
}

contract MessageSender2 {
    function send2(
        ITransmitter transmitter,
        uint32 destinationDomain,
        address recipientAddress
    ) external {
        bytes32 recipient = bytes32(uint256(uint160(recipientAddress)));

        transmitter.sendMessage(destinationDomain, recipient, 'First');
        transmitter.sendMessage(destinationDomain, recipient, 'Second');
    }    
}