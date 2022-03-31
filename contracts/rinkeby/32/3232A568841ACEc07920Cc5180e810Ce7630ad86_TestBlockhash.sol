// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestBlockhash {
    uint256 public blockNumber;
    bytes32 public blockHash;

    function storeCurrentBlockData() external {
        blockNumber = block.number;
        blockHash = blockhash(blockNumber);
    }

    function storePreviousBlockData() external {
        blockNumber = block.number - 1;
        blockHash = blockhash(blockNumber);
    }

}