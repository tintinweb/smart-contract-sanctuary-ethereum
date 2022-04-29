// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISeederV2.sol";

interface ITestSeedStorage {
    function setRandomness(bytes32 key, uint256 value) external;
}

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
contract TestSeederV2 is ISeederV2 {
    ITestSeedStorage _testSeedStorage;
    uint256 _batch;
    mapping(uint256 => bytes32) batchToReqId;
    uint256 _lastBatchTimestamp;
    uint256 _batchCadence = 90;

    constructor(address testSeedStorage) {
        _testSeedStorage = ITestSeedStorage(testSeedStorage);
    }

    function setBatch(uint256 batch) external {
        _batch = batch;
    }

    function setBatchCadence(uint256 batchCadence) external {
        _batchCadence = batchCadence;
    }

    function setBatchToReqId(uint256 batch, bytes32 reqId) external {
        batchToReqId[batch] = reqId;
    }

    function setLastBatchTimestamp(uint256 value) external {
        _lastBatchTimestamp = value;
    }

    function getNextAvailableBatch() external view returns (uint256) {
        return _lastBatchTimestamp + _batchCadence;
    }

    function executeRequestMulti() external {
        // NOTE: Poor man's randomness generator - use this **ONLY** when testing
        // Simulate generating a randomness request for the current round...
        batchToReqId[_batch] = keccak256(
            abi.encodePacked(block.timestamp, _batch)
        );
        // ...and immediatelly fulfilling it
        _testSeedStorage.setRandomness(
            batchToReqId[_batch],
            uint256(keccak256(abi.encodePacked(block.timestamp, block.number)))
        );
        _batch += 1;
        _lastBatchTimestamp = block.timestamp;
    }

    function getBatch() external view override returns (uint256) {
        return _batch;
    }

    function getReqByBatch(uint256 batch)
        external
        view
        override
        returns (bytes32)
    {
        return batchToReqId[batch];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
interface ISeederV2 {
    function getBatch() external view returns (uint256);
    function getReqByBatch(uint256 batch) external view returns (bytes32);
    function getNextAvailableBatch() external view returns (uint256);

    function executeRequestMulti() external;
}