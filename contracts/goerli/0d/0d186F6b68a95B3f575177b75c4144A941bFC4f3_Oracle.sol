// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.0;

/// @title Oracle for Lottery Game
/// @author Sparx - https://github.com/letsgitcracking
/// @notice WARNING - NEVER USE IN PRODUCTION - FOR EDUCATIONAL PURPOSES ONLY!

contract Oracle {
    // Hide seed value!!
    uint8 private seed;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(uint8 _seed) public {
        owner = msg.sender;
        seed = _seed;
    }

    function getRandomNumber() external view returns (uint256) {
        return block.number % seed;
    }

    function changeSeed(uint8 _seed) external onlyOwner {
        seed = _seed;
    }
}