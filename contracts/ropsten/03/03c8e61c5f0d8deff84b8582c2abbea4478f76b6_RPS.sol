/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    // 송금 가능하다는 것 명시
    constructor () payable {}

    // 가위/바위/보 값에 대한 enum(범주형)
    enum Hand {
        rock, paper, scissors
    }

    // 플레이어의 상태
    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    // 플레이어 구조체
    struct Player {
        address payable addr;   // 주소
        uint256 playerBetAmount;    // 배팅 금액
        Hand hand;  // 플레이어가 낸 가위/바위/보 값
        PlayerStatus playerStatus;  // 사용자의 현 상태
    }

    // 게임의 상태
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    // 게임 구조체
    struct Game {
        Player originator;  // 방장 정보
        Player taker;   // 참여자 정보
        uint256 betAmount;  // 총 베팅 금액
        GameStatus gameStatus;  // 게임의 현 상태
    }

    // mapping: python의 dict 형태
    // rooms 변수에 uint 형식의 key 값: Game 형태의 value 값을 저장 (스토리지에 저장)
    mapping(uint => Game) rooms;    // rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식
    uint roomLen = 0;   // rooms의 키 값으로, 방이 생성될 때마다 1씩 올라감

    // 방장이 낸 값(가위/바위/보)이 올바른지 확인하기 위한 제어자
    modifier isValidHand (Hand _hand) {
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }
    // 1. 방장(originator)가 createRoom을 호출
    // args: 가위/바위/보 값, 베팅 금액
    // 새로운 방을 만들고, 방 번호를 return
    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {   // 베팅 금액 설정하기 때문에 payable
        rooms[roomLen] = Game({
            betAmount: msg.value,   // msg.value는 함수 내 parameter로 따로 설정하지 않는다.
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            // 임의로 데이터를 넣고, Player 구조체 형식의 데이터로 초기화함
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;  // 변수 roomNum 값을 return
        roomLen = roomLen+1;    // 다음 방 번호를 설정
    }
    // 2. 참가자(taker)는 joinRoom을 호출
    // args: 방 번호, 가위/바위/보 값, 베팅 금액
    // 참가자를 방에 참여시키고, 방장-참가자의 가위/바위/보 값을 확인 후 방의 승자를 설정
    function joinRoom (uint roomNum, Hand _hand) public payable isValidHand(_hand) {
        rooms[roomNum].taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });

        // 참가자가 참여하였기 때문에, 게임 베팅 금액을 추가해준다.
        // rooms[roomNum] => Game 객체
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;

        // 게임 결과 업데이트 함수 호출
        compareHands(roomNum);
        
    }
        // 가위바위보 값에 따라, 방장과 참가자의 playerStatus를 설정
        function compareHands(uint roomNum) private {
            uint8 originator = uint8(rooms[roomNum].originator.hand);
            uint8 taker = uint8(rooms[roomNum].taker.hand);

            rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

            // 비긴 경우
            if (taker == originator) {
                rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
                rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            }
            // 방장이 이긴 경우
            else if ((taker + 1) % 3 == originator) {
                rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
                rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
            }
            // 참가자가 이긴 경우
            else if ((originator + 1) % 3 == taker) {
                rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
                rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
            }
            // 그 외의 상황에는 게임 상태를 에러로 업데이트
            else {
                rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
            }
        }

    // 3. 방장(originator) 혹은 참가자(taker)는 checkTotalPay 함수를 호출
    // args: 방 번호
    // 해당 방 배팅금액 return
    function checkTotalPay (uint roomNum) public view returns (uint roomNumPay) {
        return rooms[roomNum].betAmount;
    }

    // payout 함수의 제어자
    // 참가자가 중간에 자신이 낸 값을 변경할 수도 있기 떄문에
    // payout 전, 해당 함수 실행 주체가 방장||참가자인지 확인
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    // 4. 방장 혹은 참가자가 payout 함수 호출
    // args: 게임을 끝낼 방 번호
    // 게임 결과에 따라 베팅 금액 송금
    function payout (uint roomNum) public payable isPlayer(roomNum, msg.sender) {

        // 비긴 경우 -> 베팅 금액을 다시 돌려줌
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            // ADDRESS.transfer(value) 함수를 사용하면 ADDRESS로 value만큼 송금한다.
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        }
        else {
            // 방장이 이긴 경우
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }
            // 참가자가 이긴 경우
            else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }
            // 오류인 경우 => 배팅 금액을 다시 돌려줌
            else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        // 게임이 종료되었으므로, 게임 상태 변경
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}