/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BadLottery {
    uint256 public constant TOTAL_SIZE = 100_000;
    address public winner;

    function enterLottery(uint256 guess) public {
        require(winner == address(0), "Winner selected");
        uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % TOTAL_SIZE;
        if(randomNumber == guess){
            winner = msg.sender;
        }
    }
}