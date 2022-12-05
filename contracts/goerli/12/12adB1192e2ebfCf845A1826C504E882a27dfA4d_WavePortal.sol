// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

error WavePortal__MsgToYourself();
error WavePortal__IsOnCooldown();
error WavePortal__WaveDoesntExist();
error WavePortal__WaveAlreadyLiked();
error WavePortal__WaveWasntSentByYou();

contract WavePortal {
    uint256 private idCounter;
    uint256 private totalWaves;
    address public owner;

    event NewWave(address indexed from, uint256 timestamp, string message);
    event ToggleLike(address indexed from, uint256 waveId, bool like);
    event WaveRemoved(address indexed from, uint256 waveId);

    struct Wave {
        uint256 id;
        address waver;
        uint256 timestamp;
        string message;
        uint256 likesAmount;
    }

    Wave[] private waves;

    mapping(address => uint256) public lastWavedAt;
    // Wave Id => address liked
    mapping(uint256 => mapping(address => bool)) likes;

    constructor() {
        owner = msg.sender;
    }

    function toggleLike(uint256 waveId) public {
        if (waves[waveId].timestamp == 0) {
            revert WavePortal__WaveDoesntExist();
        }

        if (likes[waveId][msg.sender]) {
            likes[waveId][msg.sender] = false;
            waves[waveId].likesAmount -= 1;
        } else {
            likes[waveId][msg.sender] = true;
            waves[waveId].likesAmount += 1;
        }

        emit ToggleLike(msg.sender, waveId, likes[waveId][msg.sender]);
    }

    function deleteWave(uint256 waveId) public {
        if (waves[waveId].timestamp == 0) {
            revert WavePortal__WaveDoesntExist();
        }
        if (waves[waveId].waver != msg.sender && msg.sender != owner) {
            revert WavePortal__WaveWasntSentByYou();
        }
        for (uint i = waveId; i < waves.length - 1; i++) {
            waves[i] = waves[i + 1];
        }
        waves.pop();

        emit WaveRemoved(msg.sender, waveId);
    }

    function wave(string memory _message) public {
        uint256 likesCounter = 0; // initially waves have 0 likes
        if (msg.sender == owner) {
            revert WavePortal__MsgToYourself();
        }
        if (lastWavedAt[msg.sender] + 1 hours > block.timestamp) {
            revert WavePortal__IsOnCooldown();
        }
        totalWaves += 1;
        lastWavedAt[msg.sender] = block.timestamp;

        waves.push(
            Wave(idCounter, msg.sender, block.timestamp, _message, likesCounter)
        );
        idCounter++;
        emit NewWave(msg.sender, block.timestamp, _message);
    }

    function getTotalWavesCount() public view returns (uint256) {
        return totalWaves;
    }

    function getWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getWaveById(uint256 waveId) public view returns (Wave memory) {
        if (waves[waveId].timestamp == 0) {
            revert WavePortal__WaveDoesntExist();
        }

        return waves[waveId];
    }
}