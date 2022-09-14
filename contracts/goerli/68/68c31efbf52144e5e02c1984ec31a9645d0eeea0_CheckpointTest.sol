/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CheckpointTest {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    mapping (address => mapping (uint32 => Checkpoint)) public checkpointStructs;


    //     | <-- fromBlock (32 bits) --> | <-- votes (224 bits) --> |
    mapping (address => mapping (uint32 => uint256)) public checkpointBytes;
    uint256 constant internal BLOCK_MASK = type(uint256).max << 224;  // 111100000000
    uint256 constant internal VOTES_MASK = type(uint256).max >> 32;   // 000011111111

    function _writeCheckpointStruct(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        external  // warning for test purposes only
    {
        require(newVotes < 2**224, "Lambo::_writeCheckpoint: newVotes exceeds 224 bits");
        require(block.number < 2**32, "Lambo::_writeCheckpoint: block number exceeds 32 bits");
        uint32 blockNumber = uint32(block.number);

        if (nCheckpoints > 0 && checkpointStructs[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpointStructs[delegatee][nCheckpoints - 1].votes = uint224(newVotes);  // safe conversion since it's already checked
        } else {
            checkpointStructs[delegatee][nCheckpoints] = Checkpoint(blockNumber, uint224(newVotes));  // safe conversion since it's already checked
        }
    }

    function _writeCheckpointBytes(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        external  // warning for test purposes only
    {
        require(newVotes < 2**224, "Lambo::_writeCheckpoint: newVotes exceeds 224 bits");
        require(block.number < 2**32, "Lambo::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && (checkpointBytes[delegatee][nCheckpoints - 1] >> 224) == block.number) {
            uint256 current = checkpointBytes[delegatee][nCheckpoints - 1];
            checkpointBytes[delegatee][nCheckpoints - 1] = (current & BLOCK_MASK) | newVotes;
        } else {
            checkpointBytes[delegatee][nCheckpoints] = (block.number << 224) | newVotes;
        }
    }
}