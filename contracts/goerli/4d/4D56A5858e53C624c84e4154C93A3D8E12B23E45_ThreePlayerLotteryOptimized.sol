// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

//Optimized Contract

contract ThreePlayerLotteryOptimized {
    address payable[] public players;    
    uint256 public constant TICKET_PRICE = 10000000000000000;
    uint256 public constant MAX_PLAYERS = 3;
    uint256 public ticketsSold;
    uint256 public jackpotAmount;

    event NewPlayer(address indexed player, uint256 indexed ticketsSold, uint256 indexed jackpotAmount);
    event WinnerSelected(address indexed winner, uint256 indexed jackpotAmount);

    constructor() {}

    function buyTicket() public payable {
        require(msg.value == TICKET_PRICE, "You need to send exactly 0.01 ETH to play");
        require(players.length < MAX_PLAYERS, "Max players reached");
        players.push(payable(msg.sender));  
        ticketsSold++;
        jackpotAmount += msg.value;
        emit NewPlayer(msg.sender, ticketsSold, jackpotAmount);
        if (players.length == MAX_PLAYERS) {
            selectWinner();
        }
    }

    function selectWinner() private {
        require(players.length == MAX_PLAYERS, "There needs to be three players before selecting winner");
        address payable winner = players[uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % MAX_PLAYERS];
        winner.transfer(jackpotAmount);
        emit WinnerSelected(winner, jackpotAmount);
        resetLottery();
    }

    function resetLottery() private {
        for (uint256 i = 0; i < players.length; i++) {
            delete players[i];
        }
        ticketsSold = 0;
        jackpotAmount = 0;
    }
}