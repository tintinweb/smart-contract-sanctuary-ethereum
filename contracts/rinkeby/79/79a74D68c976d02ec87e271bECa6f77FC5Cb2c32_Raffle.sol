/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

contract Raffle {
    address owner;
    // uint256 duration;
    uint256 pot;
    uint256 playerCount;
    // address winner;
    uint256 start = 0;

    address[] players;

    mapping(address => uint256) amountEntered;

    constructor() {
        owner = msg.sender;
        start = block.timestamp;
        // duration = _duration;
    }

    function enterRaffle() public payable {
        amountEntered[msg.sender] = msg.value;
        pot += msg.value;
        playerCount++;
        players.push(msg.sender);
    }

    function pickRandomWinner() public {
        uint256 winningTicket = getRandomNumber() % pot;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (currentIndex + amountEntered[players[i]] >= winningTicket) {
                // winner = players[i];
                (bool sent, ) = payable(players[i]).call{value: pot}("");
                require(sent, "Failed to send Ether");
                for (uint256 j = 0; j < players.length; j++) {
                    amountEntered[players[j]] = 0;
                }
                pot = 0;
                playerCount = 0;
                delete players;
                start = block.timestamp;
                return;
            }
            currentIndex += amountEntered[players[i]];
        }
    }

    function getRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    // function withdraw() public {
    //     require(msg.sender == winner, "Not the winner");
    //     (bool sent, ) = payable(msg.sender).call{value: pot}("");
    //     require(sent, "Failed to send Ether");
    // }

    function getPlayerCount() public view returns (uint256) {
        return playerCount;
    }

    function trigger() external {
        if (block.timestamp > start + 6646) {
            pickRandomWinner();
        }
    }
}