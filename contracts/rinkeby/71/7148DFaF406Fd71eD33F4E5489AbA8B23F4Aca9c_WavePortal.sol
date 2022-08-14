//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract WavePortal {
    uint256 totalWaves;
    uint256 private seed;

    event NewWave(address indexed from, uint256 timestamp, string message,uint256 ethWon, bool);

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    Wave[] waves;
    mapping(address => uint256) public lastWavedAt;
    constructor() payable {
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function wave(string memory _message) public {
        require(
            lastWavedAt[msg.sender] + 30 seconds < block.timestamp,
            "Must wait 30 seconds before waving again."
        );
        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;

        waves.push(Wave(msg.sender, _message, block.timestamp));
        seed = (block.difficulty + block.timestamp + seed) % 100;

        if (seed <= 50) {
            uint256 prizeAmount = 0.0001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than the contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
            emit NewWave(msg.sender, block.timestamp, _message,prizeAmount, true);
        }else{
            emit NewWave(msg.sender, block.timestamp, _message, 0, false);
        }

        
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves; 
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }
}