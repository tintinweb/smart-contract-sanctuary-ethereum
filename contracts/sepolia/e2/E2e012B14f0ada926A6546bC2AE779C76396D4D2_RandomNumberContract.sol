// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomNumberContract {
    uint256 public overCount;
    uint256 public underCount;
    uint256 public ratio;

    function getRandomNumber() external {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.coinbase, blockhash(block.number))));
        
        if (randomNumber < uint256(0.5 * 2**256)) {
            underCount++;
        } else {
            overCount++;
        }

        ratio = underCount / overCount;
    }
}