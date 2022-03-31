// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISeederV2.sol';
import './ISeedStorage.sol';

/// @title Access to the batch seeder used by the Raid Party game
contract RpSeeder is ISeederV2, ISeedStorage {
    ISeederV2 private immutable seederV2;
    ISeedStorage private immutable seedStorage;

    constructor(address seederV2_, address seedStorage_) {
        seederV2 = ISeederV2(seederV2_);
        seedStorage = ISeedStorage(seedStorage_);
    }

    function getBatch() external override view returns (uint256) {
        return seederV2.getBatch();
    }

    function getReqByBatch(uint256 batch) external override view returns (bytes32) {
        return seederV2.getReqByBatch(batch);
    }

    function getRandomness(bytes32 key) external override view returns (uint256) {
        return seedStorage.getRandomness(key);
    }
}