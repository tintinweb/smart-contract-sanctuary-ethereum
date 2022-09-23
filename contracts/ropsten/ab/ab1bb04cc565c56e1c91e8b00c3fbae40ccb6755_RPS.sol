/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  constructor() payable {}

  enum creatorHand {
    rock,
    paper,
    scissors
  }

  enum Hand {
    rock,
    paper,
    scissors
  }

  enum PlayerStatus {
    STATUS_WIN,
    STATUS_LOSE,
    STATUS_TIE,
    STATUS_PENDING
  }

  enum GameStatus {
    STATUS_NOT_STRTED,
    STATUS_STARTED,
    STATUS_COMPLETE,
    STATUS_ERROR
  }

  struct Creator {
    address payable addr; // 주소
    uint256 playerBetAmount; // 베팅 금액
    bytes32 hand; // 플레이어가 낸 가위/바위/보
    PlayerStatus playerStatus;
  }

  struct Player {
    address payable addr; // 주소
    uint256 playerBetAmount; // 베팅 금액
    Hand hand; // 플레이어가 낸 가위/바위/보
    PlayerStatus playerStatus;
  }

  struct Game {
    Creator originator; // 방장 정보
    Player taker; // 참여자 정보
    uint256 betAmount; // 총 베팅 금액
    GameStatus gameStatus; // 게임의 현 상태
  }

  mapping(uint256 => Game) rooms; // rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식
  uint256 roomLen = 0; // rooms의 키 값, 방이 생성될 때마다 1씩 올라감

  modifier isValidHand(Hand _hand) {
    require(
      (_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors)
    );
    _;
  }

  function hashFunction(uint256 _hand, string memory _secret)
    public
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(_hand, _secret));
  }

  function createRoom(bytes32 _hand)
    public
    payable
    returns (
      // isValidHand(_hand)
      uint256 roomNum
    )
  {
    // 베팅금액을 설정하기 때문에 payable 키워드를 사용

    rooms[roomLen] = Game({
      betAmount: msg.value,
      gameStatus: GameStatus.STATUS_NOT_STRTED,
      originator: Creator({
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

  function joinRoom(uint256 roomNum, Hand _hand)
    public
    payable
    isValidHand(_hand)
  {
    rooms[roomNum].taker = Player({
      hand: _hand,
      addr: payable(msg.sender),
      playerStatus: PlayerStatus.STATUS_PENDING,
      playerBetAmount: msg.value
    });
    rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
    // compareHands(roomNum);
  }

  function compareHands(
    uint256 roomNum,
    uint256 _hand,
    string memory _secret
  ) private {
    uint256 originator;
    uint256 taker;
    bytes32 validateHand = keccak256(abi.encodePacked(_hand, _secret));
    require(
      validateHand == rooms[roomNum].originator.hand,
      'Creator Must submit right hand and secret'
    );
    originator = _hand;
    taker = uint8(rooms[roomNum].taker.hand);

    rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

    if (taker == originator) {
      // 비긴 경우
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
    } else if ((taker + 1) % 3 == originator) {
      // 방장이 이긴 경우
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
    } else if ((originator + 1) % 3 == taker) {
      // 참가자가 이긴 경우
      rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
      rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
    } else {
      // 그 외의 상황에는 게임 상태를 에러로 업데이트한다
      rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
    }
  }

  modifier isPlayer(uint256 roomNum, address sender) {
    require(
      sender == rooms[roomNum].originator.addr ||
        sender == rooms[roomNum].taker.addr
    );
    _;
  }

  function payout(
    uint256 roomNum,
    uint256 _hand,
    string memory _secret
  ) public payable isPlayer(roomNum, msg.sender) {
    compareHands(roomNum, _hand, _secret);
    if (
      rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE &&
      rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE
    ) {
      rooms[roomNum].originator.addr.transfer(
        rooms[roomNum].originator.playerBetAmount
      );
      rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    } else {
      if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
      } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
      } else {
        rooms[roomNum].originator.addr.transfer(
          rooms[roomNum].originator.playerBetAmount
        );
        rooms[roomNum].taker.addr.transfer(
          rooms[roomNum].taker.playerBetAmount
        );
      }
    }
    rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임이 종료되었으므로 게임 상태 변경
  }
}