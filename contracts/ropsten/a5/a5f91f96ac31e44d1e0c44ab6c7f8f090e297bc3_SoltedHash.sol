/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor () payable{}

    enum Hand { // 가위바위보
        rock, paper, scissors
    }

    enum PlayerStatus { // 플레이어 상태
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    struct Player {
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        PlayerStatus playerStatus;
    }

    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STAUS_COMPLETE, STATUS_ERROR
    }

    struct Game {
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
    }

    mapping(uint => Game) public rooms; // rooms[0], rooms[1] 형식으로 접근
    uint roomLen = 0; // rooms의 키. 방이 생성될 때마다 1씩 올라감

    modifier isValidHand(Hand _hand) { // Hand형 입력인지 검사
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    function getSaltedHash(Hand _hand, string memory _salt) public pure isValidHand(_hand) returns (bytes32) {
        return keccak256(abi.encodePacked(_hand,_salt));
    }

    function createRoom(Hand _hand) public payable isValidHand(_hand) returns(uint roomNum) { // 방 만들기. 베팅금액을 설정해야 하므로 payable, 방번호를 반환
        rooms[roomLen] = Game({
            originator: Player({
                addr: payable(msg.sender),
                playerBetAmount: msg.value,
                hand: _hand,
                playerStatus: PlayerStatus.STATUS_PENDING
            }),
            taker: Player({ // Player 구조체 형식의 데이터로 초기화되어야 하기 때문에 addr에는 방장의 주소를, hand는 Hand.rock으로 임시할당
                addr: payable(msg.sender),
                playerBetAmount: 0,
                hand: Hand.rock,
                playerStatus: PlayerStatus.STATUS_PENDING
            }),
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED
        });
        roomNum = roomLen;  // 생성된 방의 벙호를 리턴
        roomLen = roomLen + 1; // 다음 방 번호를 위한 1 증가
    }

    function joinRoom(uint _roomNum, Hand _hand) public payable isValidHand(_hand) {  // 만들어져 있는 방에 조인
        rooms[_roomNum].taker = Player({
            addr: payable(msg.sender),
            playerBetAmount: msg.value,
            hand: _hand,
            playerStatus: PlayerStatus.STATUS_PENDING
        });
        rooms[_roomNum].betAmount = rooms[_roomNum].betAmount + msg.value;
        compareHands(_roomNum);
    }

    function compareHands(uint _roomNum) private { // 가위바위보를 비교
        uint8 originator = uint8(rooms[_roomNum].originator.hand);  // enum을 정수형으로
        uint8 taker = uint8(rooms[_roomNum].taker.hand);

        rooms[_roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if (taker == originator){ // 비긴 경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        } else if((taker + 1) % 3 == originator){  // 방장이 이긴 경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        } else if((originator + 1) % 3 == taker){  // 참가자가 이긴 경우
            rooms[_roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[_roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else{ 
            rooms[_roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    modifier isPlayer(uint _roomNum, address sender){  // payout 함수의 실행자가 방장 또는 참가자인지 확인
        require(sender == rooms[_roomNum].originator.addr || sender == rooms[_roomNum].taker.addr);
        _;
    }

    function payout(uint _roomNum) public payable isPlayer(_roomNum, msg.sender){
        if (rooms[_roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[_roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].originator.playerBetAmount);
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].taker.playerBetAmount);
        } else if(rooms[_roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].betAmount);
        } else if(rooms[_roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].betAmount);
        } else{
            rooms[_roomNum].originator.addr.transfer(rooms[_roomNum].originator.playerBetAmount);
            rooms[_roomNum].taker.addr.transfer(rooms[_roomNum].taker.playerBetAmount);
        }

        rooms[_roomNum].gameStatus = GameStatus.STAUS_COMPLETE;
    } 
}

contract SoltedHash {
    enum Hand { // 가위바위보
        rock, paper, scissors
    }

    modifier isValidHand(Hand _hand) { // Hand형 입력인지 검사
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    function getSaltedHash(Hand _hand, string memory _salt) public pure isValidHand(_hand) returns (bytes32) {
        return keccak256(abi.encodePacked(_hand,_salt));
    }
}