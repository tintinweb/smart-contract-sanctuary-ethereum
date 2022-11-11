// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract rps {

  address emptyAddress = 0x0000000000000000000000000000000000000000;

  enum GameStatus{ InviteSent, InviteAccepted, FirstPlayerDidMove, SecondPlayerDidMove }

  struct Game {
      uint256 id;
      GameStatus status;
      address player1;
      address player2;
      uint256 player1EncodedMove;
      uint256 player1Move;
      uint256 player2Move;
      address winner;
    }

  event InviteSent(uint256 gameId, address player, address invitee);
  event InviteAccepted(uint256 gameId, address inviter, address invitee);

  mapping(uint256 => Game) public games;
  mapping(address => mapping(address => bool)) public activeInvitations;


  uint256 public nextGameId = 0;

  function update(uint256 newGameID) public {
      nextGameId = newGameID;
  }

  function invite(
    address invitee
  ) external {

    require(activeInvitations[invitee][msg.sender] == false, "Already invited");

    games[nextGameId] = Game(
      {
        id : nextGameId,
        status : GameStatus.InviteSent,
        player1 : msg.sender,
        player2 : invitee,
        player1EncodedMove : 0,
        player1Move : 0,
        player2Move : 0,
        winner : emptyAddress
      }
    );

    activeInvitations[invitee][msg.sender] == true;
    
    emit InviteSent(nextGameId, msg.sender, invitee);
    nextGameId++;
  }

  // function acceptInvite(
  //   uint256 gameId
  // ) external {

  //   Game game = games[gameId];
  //   require(activeInvitations[game.player2][msg.sender] == false, "Already invited");

  //   games[nextGameId] = Game(
  //     {
  //       id : nextGameId,
  //       status : GameStatus.InviteSent,
  //       player1 : msg.sender,
  //       player2 : invitee,
  //       player1EncodedMove : 0,
  //       player1Move : 0,
  //       player2Move : 0,
  //       winner : emptyAddress
  //     }
  //   );

  //   activeInvitations[invitee][msg.sender] == true;
    
  //   emit InviteSent(nextGameId, msg.sender, invitee);
  //   nextGameId++;
  // }

}