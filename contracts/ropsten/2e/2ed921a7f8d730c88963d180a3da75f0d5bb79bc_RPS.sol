/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
  constructor() {}

  event whoWin(string winner, string loser);
  event tie(string tie);

  enum Hand {
    rock,
    paper,
    scissors
  }

  enum PlayerStatus {
    win,
    lose,
    tie,
    pending
  }

  enum GameStatus {
    pending,
    start,
    compelete
  }

  struct Player {
    address addr;
    uint256 playerBetAmount;
    bytes32 blindedHand;
    Hand hand;
    PlayerStatus playerStatus;
  }

  struct Game {
    Player originator;
    Player joiner;
    uint256 gameBetAmount;
    GameStatus gameStatus;
  }

  mapping(uint256 => Game) rooms;
  uint256 roomLength = 0;

  modifier isValid(Hand _hand) {
    require(
      (_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors),
      "It's not Valid"
    );
    _;
  }

  // 게임을 실행해보니, originator가 금액을 지불하고 방을 만들었는데 joiner는 돈을 지불하지 않고 참여해서 이기면 돈을 가져가는 구조가 발생했다.
  // 아래 modifier에서는 require문을 통해서 joiner가 참여할 때 originator가 지불한 금액과 같은 amount를 지불해야하도록 강제한다.
  // => joinGame 함수에 적용
  modifier FairGame(uint256 originatorBetAmount) {
    require(
      originatorBetAmount == msg.value,
      "Your payment must be equal to originator's. Click the function 'checkRoomAmout' with roomNumber"
    );
    _;
  }

  // originator가 되어 방을 만들 때 hand값 + salt 단어를 keccak256 함수로 해싱한 값을 넣는다.
  // 이를 위해 struct Player에 bytes32 타입의 blindedHand 값을 추가해주었다.
  function createGame(bytes32 blindedHand) public payable returns (uint256) {
    rooms[roomLength] = Game({
      originator: Player({
        addr: payable(msg.sender),
        playerBetAmount: msg.value,
        blindedHand: blindedHand,
        hand: Hand.rock,
        playerStatus: PlayerStatus.pending
      }),
      joiner: Player({
        addr: payable(msg.sender),
        playerBetAmount: 0,
        blindedHand: "0x0",
        hand: Hand.rock,
        playerStatus: PlayerStatus.pending
      }),
      gameBetAmount: msg.value,
      gameStatus: GameStatus.pending
    });
    rooms[roomLength].gameBetAmount = rooms[roomLength]
      .originator
      .playerBetAmount;

    uint256 roomNum = roomLength;
    roomLength = roomLength + 1;
    return roomNum;
  }

  // 룸 넘버를 입력하여 해당 룸의 예치금이 얼마인지 확인하고 그에 맞춰 룸에 입장할 수 있도록 도와주는 함수
  function checkRoomAmount(uint256 roomNum)
    public
    view
    returns (uint256 amount)
  {
    amount = rooms[roomNum].gameBetAmount / 1 ether;
  }

  // joiner가 originator와 같은 amount의 value를 지불하도록 강제하기위해 rooms에 저장되어있는 originator의 amount를 modifier의 인자로 건네주었다.
  // joiner는 위 checkRoomAmount 함수를 통해 룸에 예치되어있는 금액을 확인하고 이에 맞춰 금액을 지불해야 입장할 수 있다.
  // ++ joiner는 게임에 입장할 때 해싱된 값이 아닌 _hand값을 넣는다. 그 이유는, originator가 방을 만들 때 그것을 보고 joiner가 자신의 값을 정해서 승부를 조작 할 수는 있지만
  // 반대로 originator는 joiner의 hand를 보고 자신의 값을 다시 바꿀 수가 없기 때문이다.
  function joinGame(uint256 roomNum, Hand _hand)
    public
    payable
    FairGame(rooms[roomNum].originator.playerBetAmount)
    isValid(_hand)
  {
    rooms[roomNum].joiner = Player({
      addr: payable(msg.sender),
      playerBetAmount: msg.value,
      blindedHand: "0x0",
      hand: _hand,
      playerStatus: PlayerStatus.pending
    });

    rooms[roomNum].gameBetAmount = rooms[roomNum].gameBetAmount + msg.value;
  }

  // 자신의 hand와 salt값을 넣어 원래 내고자 했던 hand값을 대입하는 과정
  // 이전에 방을 만들 때 parameter로 넣은 blindedHand 값과 현재 parameter로 받은 _hand + salt를 해싱한 값이 같으면 originator의 hand 값에 _hand 값을 넣어준다.
  function unBlind(
    uint256 roomNum,
    Hand _hand,
    string memory salt
  ) public {
    // 방의 originator만 unBlind 함수를 실행할 수 있다.
    require(msg.sender == rooms[roomNum].originator.addr);
    // joiner가 입장한 상태에서만 함수가 실행된다.
    require(rooms[roomNum].joiner.addr != address(0));
    bytes32 hash = keccak256(abi.encodePacked(uint256(_hand), salt));
    if (hash == rooms[roomNum].originator.blindedHand) {
      rooms[roomNum].originator.hand = _hand;

      // 위 일련의 과정을 거쳐 originator와 joiner의 hand가 결정되었으면 바로 compareHand 함수를 실행하여 승부를 결정짓는다.
      compareHand(roomNum);

      address payable originatorAddr = payable(rooms[roomNum].originator.addr);
      address payable joinerAddr = payable(rooms[roomNum].joiner.addr);
      uint256 gameBetAmount = rooms[roomNum].gameBetAmount;

      if (
        rooms[roomNum].originator.playerStatus == PlayerStatus.tie &&
        rooms[roomNum].joiner.playerStatus == PlayerStatus.tie
      ) {
        originatorAddr.transfer(rooms[roomNum].originator.playerBetAmount);
        joinerAddr.transfer(rooms[roomNum].joiner.playerBetAmount);
      } else if (
        rooms[roomNum].originator.playerStatus == PlayerStatus.win &&
        rooms[roomNum].joiner.playerStatus == PlayerStatus.lose
      ) {
        originatorAddr.transfer(gameBetAmount);
      } else if (
        rooms[roomNum].originator.playerStatus == PlayerStatus.lose &&
        rooms[roomNum].joiner.playerStatus == PlayerStatus.win
      ) {
        joinerAddr.transfer(gameBetAmount);
      }
    }
    // hash 값과 originator의 blindedHand 값이 다르면 트랜잭션이 중지된다.
    else {
      revert();
    }
  }

  function compareHand(uint256 roomNum) private {
    uint256 originator = uint256(rooms[roomNum].originator.hand);
    uint256 joiner = uint256(rooms[roomNum].joiner.hand);
    rooms[roomNum].gameStatus = GameStatus.start;

    if (originator == joiner) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.tie;
      rooms[roomNum].joiner.playerStatus = PlayerStatus.tie;
      emit tie("tie");
    } else if ((originator + 1) % 3 == joiner) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.lose;
      rooms[roomNum].joiner.playerStatus = PlayerStatus.win;
      emit whoWin("joiner", "originator");
    } else if ((originator + 2) % 3 == joiner) {
      rooms[roomNum].originator.playerStatus = PlayerStatus.win;
      rooms[roomNum].joiner.playerStatus = PlayerStatus.lose;
      emit whoWin("originator", "joiner");
    }
  }
}