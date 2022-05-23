/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {

    constructor () payable{}

    enum Hand { // 가위 바위 보 값에 대한 enum
        rock, paper, scissors
    }

    enum PlayerStatus {  // 플레이어의 경기 상태  /이김, 짐, 비김, 대기중
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus {   // 게임의 상태
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Player{
        address payable addr; // 주소
        uint256 playerBetAmount; // 베팅금액
        Hand hand;  // 플레이어가 낸 가위바위보
        PlayerStatus playerStatus; // 사용자의 현재 경기 상태
    }

    struct Game {
        Player originator; // 방장 정보
        Player taker;  // 참가자 정보
        uint256 betAmount; // 총 베팅 금액 
        GameStatus gameStatus; // 게임의 현 상태
    }

    mapping(uint => Game) rooms; // 게임을 진행하는 방 //rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game구조체 형식 
    uint roomLen = 0; // rooms의 키 값. 방이 생성될 때마다 1씩 증가.

    // 가위/바위/보 값에 가위, 바위, 보가 아니라 다른 값이 지정될 수도 있습니다. 
    // 따라서 createRoom이 실행되기 전에 방장이 낸 가위/바위/보 값이 올바른 값인지 확인.
    modifier isValidHandle (Hand _hand) {  
        require((_hand == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    function createRoom (Hand _hand) public payable isValidHandle(_hand) returns (uint roomNum) {  // 베팅금액을 설정하기 때문에 payable 키워드 사용
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING, // 게임 대기중
                playerBetAmount: msg.value // 방장 베팅금액
            }),
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount:0
            })
        });
        roomNum = roomLen; // roomNum은 리턴된다.
        roomLen = roomLen+1; // 다음 방 번호를 설정.
    }

    function joinRoom(uint roomNum, Hand _hand ) public payable isValidHandle(_hand) {
        rooms[roomNum].taker = Player({
        hand: _hand,
        addr: payable(msg.sender),
        playerStatus: PlayerStatus.STATUS_PENDING,  // 게임 대기중
        playerBetAmount: msg.value
            });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }

    function compareHands(uint roomNum) private {
        uint8 originator = uint8(rooms[roomNum].originator.hand); // 방장이 낸 손
        uint8 taker = uint8(rooms[roomNum].taker.hand);  // 참가자가 낸 손
  
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;  // 게임 상태 시작됨 으로 바꾸기

        if (taker == originator){ // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }
        else if ((taker +1) % 3 == originator) { // 방장이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;  // 나는 진걸로
        }
        else if ((originator + 1) % 3 == taker){  // 참가자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {  // 그 외의 상황에는 게임 상태를 에러로 업데이트한다
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }


    // 한 가지 중요한 것은 payout 함수를 실행하는 주체는 방장 또는 참가자여야 한다는 점입니다. 참가자는 중간에 자신이 낸 값을 변경할 수도 있기 때문입니다.
    // 따라서 payout 을 실행하기 전 해당 함수를 실행하는 주체가 방장 또는 참가자인지 확인하는 함수 제어자 isPlayer를 만들어야 합니다.
    // isPlayer는 방 번호와 함수를 호출한 사용자의 주소를 받습니다. 그리고 사용자의 주소가 방장 또는 참가자의 주소와 일치하는 지 확인합니다.
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    function payout(uint roomNum) public isPlayer(roomNum, msg.sender) { // 베팅금액 송금
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) { // 방장이 이기면
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);  // 방장에게 송금
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) { // 참가자가 이기면
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);  // 참가자에게 송금
            } else {  // 에러났을 때? 각자에게 다시 송금.
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임이 종료되었으므로 게임 상태 변경
    }

}