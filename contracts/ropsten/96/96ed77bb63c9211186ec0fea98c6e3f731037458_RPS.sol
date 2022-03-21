/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor () payable {} // 송금 가능한 컨트랙트의 생성자 함수

    enum Hand { // 가위바위보 값에 대한 enum
        rock, paper, scissors
    }

    enum PlayerStatus { // 플레이어의 상태
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus { // 게임의 상태
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Player { // 플레이어 구조체
        address payable addr; // 주소
        uint256 playerBetAmount; // 베팅 금액
        Hand hand; // 플레이어가 낸 가위바위보 값
        PlayerStatus playerStatus;
    }

    struct Game { // 가위바위보 게임방 구조체
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
    }

    mapping(uint => Game) rooms; // rooms[0], rooms[1]로 접근 가능, 각 요소는 Game 구조체
    uint roomLen = 0; // rooms의 키값. 방이 생성될 때마다 1씩 증가




    modifier isValidHand (Hand _hand) { // 플레이어가 낸 가위바위보 값이 올바른지 확인하는 함수 제어자
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) { // 베팅금액을 설정하므로 payable!
        // 변수 roomNum의 값을 반환해주어야 한다.
        // 방을 만들면 Game 구조체의 인스턴스를 만들어주어야 한다.
        rooms[roomLen] = Game({ // Game 인스턴스를 room에 할당
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // Player 구조체 형식으로 taker 초기화
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen; // 현재 방 번호를 roomNum에 할당시켜 반환
        roomLen = roomLen+1; // 다음 방 번호 설정
    }


    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand) {
        rooms[roomNum].taker = Player({ // taker 설정
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        // taker의 참여로 베팅 금액이 추가되었으므로, Game 인스턴스의 betAmount 변경
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        // taker 입장 완료 후, 게임 결과 업데이트 함수 호출
        compareHands(roomNum);
    }

    
    function compareHands(uint roomNum) private {
        // 방장과 참가자의 가위바위보 값을 정수형으로 바꿔준다.
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        // 비교하기에 앞서, 게임의 상태를 STARTED로 변경
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        // 가위바위보 결과 확인
        if (taker == originator) { // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }
        else if ((taker + 1) % 3 == originator) { // 방장이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1) % 3 == taker) { // 참가자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        }
        else { // 이 외의 결과에는 게임 상태를 에러로 업데이트
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }


    // payout 함수 실행자는 방장 또는 참여자여야 한다.
    modifier isPlayer (uint roomNum, address sender) {
        require (sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        // 비긴 경우에는 각자 베팅 금액을 돌려받는다.
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            // 방장이 이긴 경우
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }
            // 참가자가 이긴 경우
            else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }
            // 이외에..? 에러가 난 경우? 각자 베팅 금액을 돌려 받는다.
            else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        // 게임이 종료되었으므로 게임 상태를 변경
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}