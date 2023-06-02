/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract BlockchainRoulette {
    // Define a Player with attributes wallet, betAmount, and eliminated status
    struct Player {
        address payable wallet;
        uint betAmount;
        bool eliminated;
    }

    // Define a Game with attributes players, betAmount, game status, bulletPosition, totalPrize, winnersCount and roundEnd
    struct Game {
        Player[6] players;
        uint playerCount;
        uint betAmount;
        bool active;
        uint bulletPosition;
        uint totalPrize;
        uint winnersCount;
        bool roundEnd;
    }

    // Single active game
    Game public game;

    // Minimum bet amount for any game
    uint public minBetAmount;

    // Constructor to set the minimum bet amount
   // Constructor to set the minimum bet amount
constructor() {
    minBetAmount = 69000000000000000;
}

    // Function to create a new game with a set bet amount
    function createGame(uint _betAmount) public {
        require(_betAmount >= minBetAmount, "Bet amount is less than the minimum bet amount.");
        require(!game.active, "There is already an active game. Finish the current game first.");

        game.betAmount = _betAmount;
        game.active = false;
        game.playerCount = 0;
    }

    // Function for a player to join a specific game
    function joinGame() public payable {
        require(!game.active, "Game in progress. Wait for the next game.");
        require(msg.value == game.betAmount, "Send correct bet amount.");
        require(game.playerCount < 6, "Game is full.");

        game.players[game.playerCount] = Player(payable(msg.sender), msg.value, false);
        game.playerCount++;
    }

    // Function to start a specific game
    function startGame() public {
        require(!game.active, "Game already started.");
        require(game.playerCount > 1, "Need more players to start the game.");

        game.bulletPosition = uint(keccak256(abi.encodePacked(block.timestamp, block.prevrandao))) % game.playerCount;
        game.active = true;
    }

    // Function for a player to 'pull the trigger' in a specific game
    function pullTrigger(uint playerIndex) public {
        require(game.active, "No active game.");
        require(game.players[playerIndex].wallet == msg.sender, "Not your turn.");
        require(!game.players[playerIndex].eliminated, "You're already out of the game.");

        if (playerIndex == game.bulletPosition) {
            game.players[playerIndex].eliminated = true;
            distributePrize();
        }
    }

    // Function to distribute the prize to remaining players in a specific game
    function distributePrize() private {
        uint winnerPrize = game.totalPrize / (game.playerCount - game.winnersCount);
        game.winnersCount++;

        for (uint i = 0; i < game.playerCount; i++) {
            if (!game.players[i].eliminated) {
                game.players[i].wallet.transfer(winnerPrize);
            }
        }

        if (game.winnersCount == game.playerCount - 1) {
            endGame();
        }
    }

    // Function to end a specific game
    function endGame() private {
        for (uint i = 0; i < game.playerCount; i++) {
            delete game.players[i];
        }
        game.playerCount = 0;
        game.active = false;
    }
}