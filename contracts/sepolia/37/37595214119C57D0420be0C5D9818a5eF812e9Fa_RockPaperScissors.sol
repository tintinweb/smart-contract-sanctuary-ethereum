/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

contract RockPaperScissors {
    event GameCreated(address creator, uint gameNumber, uint bet);
    event GameStarted(address[] players, uint gameNumber);
    event GameComplete(address winner, uint gameNumber);
  
    struct Game {
       uint bet;
       address creator;
       address[] players;
       address winner;
       uint gameId;
       bool isOpen;
   }

    uint public gameNumber = 0;
    mapping(uint => mapping(address => uint)) private _gameMoves;
    mapping(uint => Game) public _games;
   
    function createGame(address payable participant) public payable {
        require(participant != address(0), "Participant address is not valid");
        require(msg.value > 0, "Value of bet must be greater than zero!");

        Game memory newGame;
        newGame.gameId = gameNumber;
        newGame.creator = payable(msg.sender);
        newGame.players[0] = participant;
        newGame.bet = msg.value;
        newGame.isOpen = true;

        _games[gameNumber] = newGame;


        emit GameCreated(msg.sender, gameNumber, msg.value);
        
        gameNumber++;
    }
  
  
    function joinGame(uint gameNumber) public payable {
        Game memory game = _games[gameNumber];

        address participant2 = payable(msg.sender);

        require(participant2 != address(0), "Invalid address");
        require(game.isOpen != false, "Game is closed");
        require(game.bet > msg.value, "Not enough ether to join the game!");
        require(game.players[0] != participant2, "You already participant of this game");

        if(msg.value > game.bet) {
            uint256 refunded = msg.value - game.bet;
            (bool success, ) = participant2.call{value: refunded}("");
            require(success, "Error of joining the game!");
        }
        game.players[1] = participant2;
        game.bet += msg.value;
        emit GameStarted(game.players, gameNumber);
    }
  
    // Rock - 1
    // Paper - 2
    // Scissors - 3
    function makeMove(uint gameNumber, uint moveNumber) public { 
        address player = msg.sender;

        Game memory game = _games[gameNumber];
        
        require(game.isOpen == true, "Game is closed");
        require(moveNumber == 1 || moveNumber == 2 || moveNumber == 3, "Invai");
        require(msg.sender != address(0), "Invalid address of message sender");
        require(game.players[0] == player || game.players[1] == player, "You are not the player of this game!");

        if(_gameMoves[gameNumber][player] == 0) {
            _gameMoves[gameNumber][player] = moveNumber;
        } else {
            return;
        }

        address player1Address = game.players[0];
        address player2Address = game.players[1];
        
        uint player1Choice = _gameMoves[gameNumber][player1Address];
        uint player2Choice = _gameMoves[gameNumber][player2Address];


        address winnerAddress = chooseWinner(player1Choice, player2Choice, player1Address, player2Address);

        if(winnerAddress == address(0)) {
            (bool success1, ) = player1Address.call{value: game.bet / 2}("");
            require(success1, "Sending ether to participant 1 not successfull");
            (bool success2, ) = player2Address.call{value: game.bet / 2}("");
            require(success2, "Sending ether to participant 2 not successfull");
        } else {
            (bool successWinner, ) = winnerAddress.call{value: game.bet}("");
            require(successWinner, "Sending ether to winner of the game not successfull");
        }

        game.isOpen = false;

        emit GameComplete(winnerAddress, gameNumber);
    }

    function chooseWinner(uint player1Choice, uint player2Choice, address player1, address player2) private pure returns(address) {
        if (player1Choice == player2Choice) {
            return address(0);
        } else if (
            (player1Choice == 1 && player2Choice == 3) || // Rock beats Scissors
            (player1Choice == 2 && player2Choice == 1) || // Paper beats Rock
            (player1Choice == 3 && player2Choice == 2)    // Scissors beats Paper
        ) {
            return player1;
        } else {
            return player2;
        }
    }

}