/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

contract TestSoc {

    event ExecutionSuccess(bytes32 packetId);
    event ExecutionFailure(bytes32 packetId);

    // packetId => status
    mapping(bytes32 => bool) public executeStatus;
    
    function test1(bytes32 packetId) public {
        emit ExecutionSuccess(packetId);
    }

    function test2(bytes32 packetId) public {
        executeStatus[packetId] = true;
        emit ExecutionFailure(packetId);
    }
}