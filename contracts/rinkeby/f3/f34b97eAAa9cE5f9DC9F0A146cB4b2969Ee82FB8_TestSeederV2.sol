// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISeederV2.sol";

interface ITestSeedStorage {
    function setRandomness(bytes32 key, uint256 value) external;
}

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
contract TestSeederV2 is ISeederV2 {
    ITestSeedStorage testSeedStorage;
    uint256 batch;
    mapping(uint256 => bytes32) batchToReqId;
    uint256 _lastBatchTimestamp = 1649198305;
    uint256 _batchCadence = 90;

    constructor(address testSeedStorage_) {
        testSeedStorage = ITestSeedStorage(testSeedStorage_);
    }

    function setBatch(uint256 batch_) external {
        batch = batch_;
    }

    function setBatchCadence(uint256 batchCadence_) external {
        _batchCadence = batchCadence_;
    }

    function setBatchToReqId(uint256 batch_, bytes32 reqId) external {
        batchToReqId[batch_] = reqId;
    }

    function setLastBatchTimestamp(uint256 value) external {
        _lastBatchTimestamp = value;
    }

    function getNextAvailableBatch() external view returns (uint256) {
        return _lastBatchTimestamp + _batchCadence;
    }

    function executeRequestMulti() external {
        // Poor man's randomness generator - ONLY use this when testing
        testSeedStorage.setRandomness(
            batchToReqId[batch],
            uint256(keccak256(abi.encodePacked(block.timestamp, block.number)))
        );

        batch = batch + 1;
        batchToReqId[batch] = keccak256(abi.encodePacked(batch));
        _lastBatchTimestamp = block.timestamp;
    }

    function getBatch() external view override returns (uint256) {
        return batch;
    }

    function getReqByBatch(uint256 batch_)
        external
        view
        override
        returns (bytes32)
    {
        return batchToReqId[batch_];
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