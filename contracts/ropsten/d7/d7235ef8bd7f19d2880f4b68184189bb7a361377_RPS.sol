/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  // Hand enumerator, each RPS represents Rock, Paper, and Scissors
  enum Hand {R, P, S}
  // Player Status enumerator
  enum PlayerStatus {WIN, LOSE, DRAW, PENDING}
  // Game Status enumerator
  enum GameStatus {NOT_START, START, FINISH, ERROR}

  // Player1 structure
  struct Player1 {
	address payable playerAddress;
	uint256 playerBettingAmount;
	bytes32 playerHand;
	PlayerStatus playerStatus;
  }

	// Player2 structure
  struct Player2 {
	  address payable playerAddress;
	  uint256 playerBettingAmount;
	  Hand playerHand;
	  PlayerStatus playerStatus;
  }

  // Game structure
  struct Game {
	Player1 player1;
	Player2 player2;
	uint256 totalBettingAmount;
	GameStatus gameStatus;
  }

  // Mapping table for rooms
  // Each room number represents specific game
  mapping(uint => Game) rooms;
  // roomNumber will increase by one when calling createRoom() function
  uint roomNumber = 0;

  // modifier to check whether player provides valid hand
  modifier isValidHand(Hand _hand) {
	require((_hand == Hand.R) || (_hand == Hand.P) || (_hand == Hand.S), "Error: Unknown hand");
	_;
  }

  // modifier to check whether player is with valid address
  modifier isValidPlayer(address _address, uint _roomNumber) {
	Game memory newRoom = rooms[_roomNumber];
	address payable player1Address = newRoom.player1.playerAddress;
	address payable player2Address = newRoom.player2.playerAddress;

	require(_address == player1Address || _address == player2Address, "Error: Address not matched");
	_;
  }

  // createRoom() function to create new game
  function createRoom(Hand _hand, string memory _password) public payable isValidHand(_hand) returns(uint) {
	rooms[roomNumber] = Game({
	  player1: Player1({
		playerAddress: payable(msg.sender),
		playerBettingAmount: msg.value,
		playerHand: keccak256(abi.encode(uint8(_hand), _password)),
		playerStatus: PlayerStatus.PENDING
	  }),
	  // player2 is initialised with temporary value. It will be initialised later with joinRoom() function
	  player2: Player2({
		playerAddress: payable(msg.sender),
		playerBettingAmount: 0,
		playerHand: Hand.R,
		playerStatus: PlayerStatus.PENDING
	  }),
	  totalBettingAmount: msg.value,
	  gameStatus: GameStatus.NOT_START
	});

	return roomNumber++;
  }

  function joinRoom(uint _roomNumber, Hand _hand) public payable isValidHand(_hand) {
	Game memory newRoom = rooms[_roomNumber];

	newRoom.player2 = Player2({
	  playerAddress: payable(msg.sender),
	  playerBettingAmount: msg.value,
	  playerHand: _hand,
	  playerStatus: PlayerStatus.PENDING
	});

	newRoom.totalBettingAmount =
	  newRoom.player1.playerBettingAmount + newRoom.player2.playerBettingAmount;
  }

  function compareHands(uint _roomNumber, string memory _password) public view {
	Game memory newRoom = rooms[_roomNumber];

	bytes32 player1HandBytes = newRoom.player1.playerHand;
	uint8 player1HandUint;
	// Check player1's hand
	for(uint8 i = 0; i < 3; i++) {
		if(keccak256(abi.encode(i, _password)) == player1HandBytes) {
			player1HandUint = i;
			break;
		}
	}
	uint8 player2HandUint = uint8(newRoom.player2.playerHand);

	Player1 memory player1 = newRoom.player1;
	Player2 memory player2 = newRoom.player2;

	newRoom.gameStatus = GameStatus.START;

	if(player1HandUint == player2HandUint) {
	  // Draw
	  player1.playerStatus = PlayerStatus.DRAW;
	  player2.playerStatus = PlayerStatus.DRAW;
	} else if((player1HandUint + 1) % 3 == player2HandUint) {
	  // Player 2 win
	  player1.playerStatus = PlayerStatus.LOSE;
	  player2.playerStatus = PlayerStatus.WIN;
	} else if((player2HandUint + 1) % 3 == player1HandUint){
	  // Player 1 win
	  player1.playerStatus = PlayerStatus.WIN;
	  player2.playerStatus = PlayerStatus.LOSE;
	} else {
	  newRoom.gameStatus = GameStatus.ERROR;
	}
  }

  function payout(uint _roomNumber) public isValidPlayer(msg.sender, _roomNumber) {
	Game memory newRoom = rooms[_roomNumber];

	PlayerStatus player1Status = newRoom.player1.playerStatus;
	PlayerStatus player2Status = newRoom.player2.playerStatus;

	address payable player1Address = newRoom.player1.playerAddress;
	address payable player2Address = newRoom.player2.playerAddress;

	uint256 player1BettingAmount = newRoom.player1.playerBettingAmount;
	uint256 player2BettingAmount = newRoom.player2.playerBettingAmount;

	if(player1Status == PlayerStatus.DRAW && player2Status == PlayerStatus.DRAW) {
	  player1Address.transfer(player1BettingAmount);
	  player2Address.transfer(player2BettingAmount);
	} else {
	  if(player1Status == PlayerStatus.WIN) {
		player1Address.transfer(newRoom.totalBettingAmount);
	  } else if(player2Status == PlayerStatus.WIN) {
		player2Address.transfer(newRoom.totalBettingAmount);
	  } else {
		player1Address.transfer(player1BettingAmount);
	  	player2Address.transfer(player2BettingAmount);
	  }
	}

	newRoom.gameStatus = GameStatus.FINISH;
  }
}