/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract RPS {
    constructor() payable {}

    // event  PlayerCheck(Player player);

    enum Hand {
        rock, paper, scissors
    }

    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Player {
        Hand hand;
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }

    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        Player originator;
        Player taker;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;

    modifier isValidHand(Hand _hand) {
        require((_hand  == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    modifier isPlayer(uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    // digest는 keccak256(encode(hand, time))한 결과값이고, time은 digest를 만들때 사용한 프로그램 실행 시간
    function createRoom(bytes32 digest, uint256 time) public payable returns (uint roomNum) {
        Hand _hand;

        bytes32 tmp;
        for(uint8 i = 0; i < 3; i++) {
            tmp = keccak256(abi.encode(i, time));
            if(tmp == digest) {
                _hand = Hand(i);
                break;
            }

            // 방장의 hand가 유효한 값이 아니면 error throw
            require((i != 2), "Invalid hand");
        }

        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            // 아래는 이후 taker가 방에 입장했을때 변경될 수 있는 값들이다.
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen + 1;

        // emit PlayerCheck(rooms[roomNum].originator);
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

        // emit PlayerCheck(rooms[roomNum].taker);
    }

    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
            // 방장이 이김
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
        } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
            // 참여자가 이김
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
        } else {
            // 비겼음
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }

    function compareHands(uint roomNum) private {
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if (taker == originator) {
            // 비겼음
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        } else if ((taker + 1) % 3 == originator) {
            // 방장이 이김
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        } else if ((originator + 1) % 3 == taker) {
            // 참여자가 이김
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }
}