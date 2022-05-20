/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  constructor () payable {}

  // 가위바위보 값
  enum Hand {
    rock, paper, scissors
  }

  // 플레이어의 상태
  enum PlayerStatus {
    STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
  }

  enum GameStatus {
    STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
  }

  struct Player {
    address payable addr; // 주소
    uint256 playerBetAmount; // 베팅 금액
    Hand hand; // 가위바위보값
    PlayerStatus playerStatus; // 사용자의 현 상태
  }

  struct Game {
    Player originator; // 방장 정보
    Player taker; // 참여자 정보
    uint256 betAmount; // 총 베팅 금액
    GameStatus gameStatus; // 게임의 현 상태
  }

  mapping(uint => Game) rooms;
  uint roomLen = 0;

  modifier isValidHand (Hand _hand) {
    require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
    _;
  }

  function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {
    rooms[roomLen] = Game({
      
      betAmount: msg.value, // msg: 글로벌 변수
      gameStatus: GameStatus.STATUS_NOT_STARTED,
      originator: Player({
        hand: _hand,
        addr: payable(msg.sender),
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: msg.value
      }),
      taker: Player({
        hand: Hand.rock,
        addr: payable(msg.sender),
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: 0
      })
    });
    roomNum = roomLen;
    roomLen = roomLen + 1;
  }

  function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand) {
    rooms[roomNum].taker = Player({
      hand: _hand,
      addr: payable(msg.sender),
      playerStatus: PlayerStatus.STATUS_PENDING,
      playerBetAmount: msg.value
    });
    rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
    compareHands(roomNum);
  }

  function compareHands(uint roomNum) private {
    uint8 originator = uint8(rooms[roomNum].originator.hand);
    uint8 taker = uint8(rooms[roomNum].taker.hand);

    rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

    if (taker == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
    }
    else if ((taker + 1) % 3 == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
    }
    else if ((originator + 1) % 3 == taker) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
    } else {
      rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
    }
  }

  modifier isPlayer (uint roomNum, address sender) {
    require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
    _;
  }

  function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
    if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
      rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
      rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    } else {
      if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
      } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
      } else {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
      }
    }
    rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
  }
}