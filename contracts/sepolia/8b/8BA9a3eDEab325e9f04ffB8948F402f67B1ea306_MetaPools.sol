/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract MetaPools {
    enum PoolType {
        Public,
        Private
    }

    struct Pool {
        uint poolId;
        uint entryFee;
        address[] participants;
        mapping(address => bytes32[]) predictions;
        bool closed;
        bool resultsDeclared;
        uint winningPredictionCount;
        uint prizePool;
        PoolType poolType;
    }

    mapping(uint => Pool) public pools;
    uint public poolCounter;

    event PoolCreated(uint poolId, uint entryFee, PoolType poolType);
    event PredictionSubmitted(uint poolId, address participant);
    event ResultsDeclared(
        uint poolId,
        uint winningPredictionCount,
        uint prizePool
    );

    function createPool(uint entryFee, PoolType poolType) external {
        poolCounter++;
        Pool storage newPool = pools[poolCounter];
        newPool.poolId = poolCounter;
        newPool.entryFee = entryFee;
        newPool.poolType = poolType;
        emit PoolCreated(poolCounter, entryFee, poolType);
    }

    function joinPool(
        uint poolId,
        bytes32[] calldata predictions
    ) external payable {
        Pool storage pool = pools[poolId];
        require(!pool.closed, "Pool is closed for predictions");

        if (pool.poolType == PoolType.Private) {
            // Add custom logic for joining a private pool
            // E.g., check if the participant is invited or has a password
            // Implement any additional validation as per your requirements
            // You may require additional storage to track private pool invitations/passwords
        }

        require(msg.value == pool.entryFee, "Incorrect entry fee");
        require(predictions.length == 10, "Invalid predictions count");

        pool.participants.push(msg.sender);
        pool.predictions[msg.sender] = predictions;

        emit PredictionSubmitted(poolId, msg.sender);
    }

    function closePool(uint poolId) external {
        Pool storage pool = pools[poolId];
        require(pool.participants.length > 0, "No participants in the pool");
        require(!pool.closed, "Pool is already closed");

        pool.closed = true;
    }

    function declareResults(uint poolId, uint winningPredictionCount) external {
        Pool storage pool = pools[poolId];
        require(pool.closed, "Pool is not closed yet");
        require(!pool.resultsDeclared, "Results already declared");
        require(
            winningPredictionCount <= 10,
            "Invalid winning prediction count"
        );

        pool.winningPredictionCount = winningPredictionCount;
        pool.prizePool = pool.entryFee * pool.participants.length;

        for (uint i = 0; i < pool.participants.length; i++) {
            address participant = pool.participants[i];
            if (
                pool.predictions[participant].length == winningPredictionCount
            ) {
                payable(participant).transfer(
                    pool.prizePool / pool.winningPredictionCount
                );
            }
        }

        pool.resultsDeclared = true;

        emit ResultsDeclared(poolId, winningPredictionCount, pool.prizePool);
    }

    function getPoolParticipants(
        uint poolId
    ) external view returns (address[] memory) {
        return pools[poolId].participants;
    }

    function getParticipantPredictions(
        uint poolId,
        address participant
    ) external view returns (bytes32[] memory) {
        return pools[poolId].predictions[participant];
    }
}