// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract RockPaperScissors {

  struct Game {
    uint gameId;
    address[] players;
    uint bet;
    mapping (address => uint) moveByAddress;
    uint makeMoveInteractions;
    uint prize;
    address winner;
  }

  mapping(uint => Game) private games;
  address private owner;

  constructor() {
    owner = msg.sender;
  }

  
  function createGame() public payable {
    require(msg.value > 0, "Bet must be higher than 0");
    Game storage game = games[block.number];
    game.bet = msg.value;
    game.prize = msg.value;
    game.players.push(msg.sender);
    game.gameId = block.number;
    
    emit GameCreated(msg.sender, block.number, msg.value);
  }
  

  function joinGame(uint gameId) public payable { 
    Game storage game = games[gameId];
    require(game.gameId != 0, "Game doesn't exsits");
    require(game.prize == game.bet, "This game alredy started");
    require(msg.value >= game.bet, "Bet must be equal or higher than game bet");

    if(msg.value > game.bet) {
      game.prize += msg.value - game.bet;
      payable(msg.sender).transfer(msg.value - game.bet);
    } else {
      game.prize += msg.value;
      uint fee = (game.prize * 300) / 10000;
      game.prize = msg.value - fee;
    }
    game.players.push(msg.sender);

    emit GameStarted(game.players, gameId);
  }
  

  function play(uint gameId, uint moveNumber) public {
    Game storage game = games[gameId];
    require(game.winner == address(0), "Game alredy finshed");
    require(game.players.length > 1, "Game must have 2 players to make a move");
    require(moveNumber > 0 && moveNumber <= 3, "Move can't be negative or more than 3");

    game.moveByAddress[msg.sender] = moveNumber;
    game.makeMoveInteractions++;

    if(game.makeMoveInteractions <= 1) {
      return;
    }

    uint creatorMove = game.moveByAddress[game.players[0]];
    uint participantMove = game.moveByAddress[game.players[1]];

    if(creatorMove == participantMove) {
      emit GameRetry(gameId);
      return;
    }

    if((creatorMove + 1) % 3 == participantMove) {
       game.winner = game.players[1];
    } else {
       game.winner = game.players[0];
    }

    payable(game.winner).transfer(game.prize);
    payable(owner).transfer(game.bet - game.prize);
    emit GameComplete(game.winner, gameId);
  }

  function getGames(uint gameId) public view onlyOwner returns (uint, address, uint, address){
    Game storage game = games[gameId];
    return (game.gameId, game.players[0], game.bet, game.winner);
  }

  modifier onlyOwner {
    require(owner == msg.sender, "Only owner can view this");
    _;
  }


  event GameCreated(address creator, uint gameId, uint bet);
  event GameStarted(address[] players, uint gameId);
  event GameRetry(uint gameId);
  event GameComplete(address winner, uint gameId);
}