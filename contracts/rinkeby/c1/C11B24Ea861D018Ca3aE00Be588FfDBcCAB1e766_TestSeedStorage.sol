// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISeedStorage.sol';

// Originally deployed at https://etherscan.io/address/0xFc8f72Ac252d5409ba427629F0F1bab113a7492F
contract TestSeedStorage is ISeedStorage {
    mapping(bytes32 => uint256) randomness;

    function setRandomness(bytes32 key, uint256 value) external {
        randomness[key] = value;
    }

    function getRandomness(bytes32 key) external override view returns (uint256) {
        return randomness[key];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0xFc8f72Ac252d5409ba427629F0F1bab113a7492F
interface ISeedStorage {
    function getRandomness(bytes32 key) external view returns (uint256);
}