// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] memory calls) external returns (uint blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }

    // Helper functions
    function getEthBalance(address addr) external view returns (uint balance) {
        balance = addr.balance;
    }

    function getBlockHash(uint blockNumber) external view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() external view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp() external view returns (uint timestamp) {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty() external view returns (uint difficulty) {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() external view returns (uint gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() external view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}