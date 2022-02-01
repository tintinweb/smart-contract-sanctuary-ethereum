/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomSeedGenerator {
    uint256 public commitDeadline;
    uint256 public revealDeadline;
    bytes32 private randomSeed;
    mapping(address => bytes32) public sealedRandomShards;

    // Commit Phase: every participant commit a sealed random shard into the state store
    // Reveal Phase: every participant reveal the previously commited randan shard which becomes a part of the final random seed.
    constructor(uint256 _commitDuration, uint256 _revealDuration) {
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = commitDeadline + _revealDuration;
    }

    function getRandomSeed() public view returns (bytes32) {
        require(
            block.timestamp >= revealDeadline,
            "Random seed not available yet"
        );
        return randomSeed;
    }

    function commit(bytes32 _sealedRandomShard) external {
        require(block.timestamp < commitDeadline, "Commit phase closed.");
        sealedRandomShards[msg.sender] = _sealedRandomShard;
    }

    function reveal(uint256 _randomShard) public {
        require(block.timestamp >= commitDeadline, "Still in commit phase.");
        require(block.timestamp < revealDeadline, "Reveal phase closed.");

        bytes32 sealedRandomShard = seal(_randomShard);
        require(
            sealedRandomShard == sealedRandomShards[msg.sender],
            "Invalid Random Shard provided!"
        );

        randomSeed = keccak256(abi.encode(randomSeed, _randomShard));
    }

    // Helper view function to seal a given _randomShard
    function seal(uint256 _randomShard) public view returns (bytes32) {
        return keccak256(abi.encode(msg.sender, _randomShard));
    }
}