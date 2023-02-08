/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  constructor () payable {}

  //가위 바위 보 값에 대한 enum
  enum Hand {
    rock, paper, scissors
  }

  //플레이어의 상태
  enum PlayerStatus {
    STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
  }
  
  //게임의 상태
  enum GameStatus {
    STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
  }

  struct Player {
    address payable addr; //주소
    uint256 playerBetAmount; //베팅 금액
    Hand hand; //플레이어가 낸 가위 바위 보 값
    PlayerStatus playerStatus; //사용자의 현 상태
  }

  struct Game {
    Player originator; //방장 정보
    Player taker; //참여자 정보
    uint256 betAmount; //총 베팅 금액
    GameStatus gameStatus; //게임의 현 상태
  }

  mapping(uint => Game) rooms; 
  uint roomLen = 0;

  modifier isValidHand (Hand _hand) {
    require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
    _;
  }

  modifier isPlayer (uint roomNum, address sender) {
    require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
    _;
  }

  function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum){
    rooms[roomLen] = Game({
      betAmount: msg.value,
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
    roomLen = roomLen+1;
  }

  function joinRoom (uint roomNum, Hand _hand) public payable isValidHand(_hand) {
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
    
    //비긴경우
    if(taker == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
    }
    //방장이 이긴경우
    else if((taker+1) % 3 == originator) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
    }
    //참가자가 이긴경우
    else if((originator + 1) % 3 == taker) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
    }
    //그외 상황은 게임상태를 에러로 업데이트
    else {
      rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
    }
  }

  function checkToTotalPay(uint roomNum) public view returns(uint roomNumPay) {
    return rooms[roomNum].betAmount;
  }

  function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
    //비긴경우
    if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
      rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
      rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    } else {
      //방장이 이긴경우
      if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
      } 
      //참가자가 이긴경우
      else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
      } 
      //오류시 환불
      else {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
      }
    }
    rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; //게임이 종료되었으므로 게임상태 변경
  }
}