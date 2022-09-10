/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

//SPDX-License-Identifier: MIT
/* Copyright (c) 2022 PowerLoom, Inc. */

pragma solidity ^0.8.17;

contract AuditRecordStorePub {
    event RecordAppended(bytes32 apiKeyHash, string snapshotCid, string payloadCommitId, uint256 tentativeBlockHeight, string projectId, uint256 indexed timestamp);

    function commitRecord(string memory snapshotCid, string memory payloadCommitId, uint256 tentativeBlockHeight, string memory projectId, bytes32 apiKeyHash) public {
        emit RecordAppended(apiKeyHash, snapshotCid, payloadCommitId, tentativeBlockHeight, projectId, block.timestamp);
    }
}