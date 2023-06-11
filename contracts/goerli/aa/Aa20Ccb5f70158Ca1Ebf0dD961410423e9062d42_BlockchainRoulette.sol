/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

//SPDX-License-Identifier: UNLICENSED//
pragma solidity ^0.8.4;

contract BlockchainRoulette {
    // Define a Player with attributes: wallet, betAmount, and eliminated status
    struct Player {
        address payable wallet;
        uint betAmount;
        bool eliminated;
    }

    // Define a Game with attributes: players, betAmount, game status, bulletPosition, and round end
    struct Game {
        Player[] players;
        uint betAmount;
        bool active;
        uint bulletPosition;
        bool roundEnd;
    }

    // Array to store multiple games
    Game[] public games;

    // Event to signal the creation of a game and return the game index
    event GameCreated(uint gameIndex);

    // Function to create a new game with a set bet amount
    function createGame(uint _betAmount) public {
        games.push();
        Game storage newGame = games[games.length - 1];
        newGame.betAmount = _betAmount;
        emit GameCreated(games.length - 1);
    }

    // Function for a player to join a specific game
    function joinGame(uint gameIndex) public payable {
        require(!games[gameIndex].active, "Game in progress. Wait for the next game.");
        require(msg.value == games[gameIndex].betAmount, "Send correct bet amount.");

        games[gameIndex].players.push(Player(payable(msg.sender), msg.value, false));
    }

    // Function to start a specific game
    function startGame(uint gameIndex) public {
        require(!games[gameIndex].active, "Game already started.");
        require(games[gameIndex].players.length > 1, "Need more players to start the game.");

        games[gameIndex].bulletPosition = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % games[gameIndex].players.length;
        games[gameIndex].active = true;
    }

    // Function for a player to 'pull the trigger' in a specific game
    function pullTrigger(uint gameIndex) public {
        require(games[gameIndex].active, "No active game.");

        // Randomly select a player
        uint playerIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % games[gameIndex].players.length;

        if (playerIndex == games[gameIndex].bulletPosition) {
            games[gameIndex].players[playerIndex].eliminated = true;
            games[gameIndex].roundEnd = true;
            
            // Check if there's only one player remaining and end the game if so
            uint playersRemaining = 0;
            address payable winner;
            for (uint i = 0; i < games[gameIndex].players.length; i++) {
                if (!games[gameIndex].players[i].eliminated) {
                    playersRemaining++;
                    winner = games[gameIndex].players[i].wallet;
                }
            }

            // End game and transfer winnings to the last player remaining
            if (playersRemaining == 1) {
                games[gameIndex].active = false;
                uint prize = games[gameIndex].betAmount * games[gameIndex].players.length;
                winner.transfer(prize);
            }
        }
    }

    // Function to retrieve game details
    function getGameDetails(uint gameIndex) public view returns (address[] memory, bool[] memory, uint) {
        Player[] memory players = games[gameIndex].players;
        address[] memory playerAddresses = new address[](players.length);
        bool[] memory playerStatuses = new bool[](players.length);
        for (uint i = 0; i < players.length; i++) {
            playerAddresses[i] = players[i].wallet;
            playerStatuses[i] = players[i].eliminated;
        }
        return (playerAddresses, playerStatuses, games[gameIndex].betAmount * players.length);
    }
}