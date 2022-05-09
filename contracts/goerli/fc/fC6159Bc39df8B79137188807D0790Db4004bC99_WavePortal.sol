/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract WavePortal {
    uint256 totalWaves;

    event NewWave(address indexed from, uint256 timestamp, string message);

    struct Wave {
        address waver; // the address of the user who waved
        string message; // the message user sent
        uint256 timestamp; // the timestamp when the user waved
    }

    Wave[] waves;

    constructor() payable {
        //console.log("Yo yo, I am a contract and I am smart");
    }

    function wave(string memory _message) public {
        totalWaves += 1;
        //console.log("%s waved with message %s", msg.sender, _message);

        waves.push(Wave(msg.sender, _message, block.timestamp));

        emit NewWave(msg.sender, block.timestamp, _message);

        uint256 prizeAmount = 0.0001 ether;
        require(
            prizeAmount <= address(this).balance,
            "Trying to withdraw more money than the contract has."
        );
        (bool success, ) = (msg.sender).call{value: prizeAmount}("");
        require(success, "Failed to withdraw money from contract.");
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        //console.log("We have %d total waves!", totalWaves);
        return totalWaves;
    }
}