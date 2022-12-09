/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract C {
    event Received(address Sender, uint Value);
    event FallbackCalled(address Sender, uint Value, bytes Data);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
}