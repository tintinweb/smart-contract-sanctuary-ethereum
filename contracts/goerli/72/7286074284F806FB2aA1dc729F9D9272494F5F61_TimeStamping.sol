// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeStamping {
    mapping(bytes32 => uint256) private _history;

    function createStamp(bytes32 hash_) external {
        require(_history[hash_] == 0, "Hash collision");

        _history[hash_] = block.timestamp;
    }

    function getHashStamp(bytes32 hash_) external view returns (uint256) {
        uint256 result = _history[hash_];
        require(result != 0, "Hash is not existing");
        return result;
    }
}