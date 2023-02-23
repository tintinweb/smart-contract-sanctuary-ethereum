/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract ThreePlayerLottery {
    address[] players;    
    uint256 public constant TICKET_PRICE = 10000000000000000;
    uint256 public constant MAX_PLAYERS = 3;
    uint256 public ticketsSold;
    uint256 public jackpotAmount;
    uint256 public numPlayers;

    constructor() {
        ticketsSold = 0;
        jackpotAmount = ticketsSold * TICKET_PRICE;
        numPlayers = players.length;
    }

    function buyTicket() public payable {
        require(msg.value >= TICKET_PRICE, "You need 0.001ETH to play");
        players.push(msg.sender);
        ticketsSold++;
    }

    function selectWinner() public returns (bool) {
        require(ticketsSold == MAX_PLAYERS, "There needs to be three players before selecting winner");
        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % MAX_PLAYERS;
        address payable winner = payable(players[winnerIndex]);
        winner.transfer(address(this).balance);
        resetRaffle();
        return true;
    }

    function resetRaffle() public {
        delete players;
        ticketsSold = 0;
        jackpotAmount = 0;
    }
}