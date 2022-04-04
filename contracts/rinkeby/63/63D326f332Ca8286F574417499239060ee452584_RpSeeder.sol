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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
interface ISeederV2 {
    function getBatch() external view returns (uint256);
    function getReqByBatch(uint256 batch) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0xFc8f72Ac252d5409ba427629F0F1bab113a7492F
interface ISeedStorage {
    function getRandomness(bytes32 key) external view returns (uint256);
}