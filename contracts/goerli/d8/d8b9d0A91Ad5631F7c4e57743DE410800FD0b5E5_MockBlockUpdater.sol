// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MockBlockUpdater {
    function checkBlockHash(uint16 index,bytes32 blockHash,bytes32 receiptsRoot, bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        return true;
    }
}