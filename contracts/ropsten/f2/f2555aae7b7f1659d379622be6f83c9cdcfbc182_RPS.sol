/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract RPS {
    constructor() payable{}

    event gameCreated(address originator, uint256 originator_bet, uint256 room_num, uint256 betAmount);
    event gameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet, uint256 betAmount);
    event originatorWin(address originator, address taker, uint256 betAmount);
    event takerWin(address originator, address taker, uint256 betAmount);

    enum Hand {
        rock, paper, scissors
    }

    // Player 상태
    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    // 게임 상태
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    // Player 구조체
    struct Player {
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        PlayerStatus playerStatus;
    }
    
    // 게임 구조체 
    struct Game {
        uint256 betAmount;
        Player originator;
        Player taker;
        GameStatus gameStatus;
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

    // 베팅 금액을 설정하기 때문에 payable키워드를 사용
    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {
        // 변수 roomNum의 값을 변환
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            // Player 초기화
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING, 
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen+1;

        emit gameCreated(msg.sender, msg.value, roomNum, rooms[roomNum].betAmount);
    }


    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand){
        emit gameJoined(rooms[roomNum].originator.addr, msg.sender, rooms[roomNum].betAmount, msg.value, rooms[roomNum].betAmount);

        rooms[roomNum].taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });

        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum);
    }

    function compareHands(uint roomNum) private{
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if((taker +1) % 3 == originator){// originator win!
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;

            emit originatorWin(rooms[roomNum].originator.addr, rooms[roomNum].taker.addr, rooms[roomNum].betAmount);
        }else if (taker == originator ){// same
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }else if ((originator+1) % 3 == taker){// taker win!
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;

            emit takerWin(rooms[roomNum].originator.addr, rooms[roomNum].taker.addr,rooms[roomNum].betAmount);
        }else{
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }


    function payout(uint roomNum) public isPlayer(roomNum, msg.sender) {
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
                emit originatorWin(rooms[roomNum].originator.addr, rooms[roomNum].taker.addr, rooms[roomNum].betAmount);
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
                emit takerWin(rooms[roomNum].originator.addr, rooms[roomNum].taker.addr,rooms[roomNum].betAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }else{
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
 }