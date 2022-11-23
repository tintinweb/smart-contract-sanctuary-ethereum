// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TimeStamping {
    mapping(bytes32 => uint256) private _history;
    event TimeStampCreated(bytes32 indexed _hash);

    function createStamp(bytes32 hash_) external {
        require(_history[hash_] == 0, "TimeStamping: Hash collision");

        _history[hash_] = block.timestamp;
        emit TimeStampCreated(hash_);
    }

    function getHashStamp(bytes32 hash_) external view returns (uint256) {
        return _history[hash_];
    }
}