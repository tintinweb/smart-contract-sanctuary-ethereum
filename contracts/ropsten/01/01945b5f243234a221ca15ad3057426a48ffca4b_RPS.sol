/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract RPS {
    constructor () payable {}

    /*
        event GameCreated(address originator, uint256 originator_bet);
        event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
        event OriginatorWin(address originator, address taker, uint256 betAmount);
        event TakerWin(address originator, address taker, uint256 betAmount);
    */

    // 가위, 바위, 보 enum
    enum Hand {
        rock, paper, sicissors
    }

    //게임 결과에 따른 상태
    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    // 각 플레이어의 정보
    struct Player {
        address payable addr; // 주소
        uint256 playerBetAmount; // 배팅 금액
        Hand hand; // 가위 바위  보 상태
        PlayerStatus playerStatus; // 게임 결과에 따른 상태
    }

    //게임의 상태
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Game {
        Player originator; // 방장 정보
        Player taker; // 참여자 정보
        uint betAmount; // 총 배팅 금액
        GameStatus gameStatus; // 게임 상태
    }

    mapping(uint => Game) rooms; //roomLen(key) => Game(value)인 배열 rooms
    uint roomLen = 0;

    //가위, 바위, 보에 대한 유효성 검사(modifier)
    modifier isVaildHand(Hand _hand) {
        require((_hand == Hand.rock) || (_hand == Hand.paper )|| (_hand == Hand.sicissors)); //함수 실행 전
        _;
    }

    //generate Key
    function GenerateKey(Hand _hand, string memory password) public view isVaildHand(_hand) returns (bytes32){
        return keccak256(abi.encodePacked(_hand,password));
    }   


    // 게임 생성
    function createRoom (bytes32 handHash, string memory password) public payable returns (uint roomNum){ // 배팅 금액에 대한 payable, 유효성 검사, 방 번호 반환
        //_hand 구하기
        Hand _hand;
        if(handHash == keccak256(abi.encodePacked(Hand.rock,password))) {
            _hand = Hand.rock;
        }
        else if (handHash == keccak256(abi.encodePacked(Hand.paper,password))) {
            _hand = Hand.paper;
        }
        else {
            _hand = Hand.sicissors;
        }


        //rooms <= Game
        rooms[roomLen] = Game({
            betAmount: msg.value, //방에 대한 배팅 값 : 초기 방장 배팅 금액
            gameStatus: GameStatus.STATUS_NOT_STARTED, // 게임이 아직 시작하지 않음
            originator: Player({ // 방장 정보
                addr: payable(msg.sender), // 방장 address -> payable 변환 필요(Player 구조체)
                playerBetAmount: msg.value, // 방장 배팅 금액
                hand: _hand, // 방장 hand
                playerStatus: PlayerStatus.STATUS_PENDING // 아직 게임 생성이기 때문에
            }),
            taker: Player({ // 참여자 정보(초기화)
                addr: payable(0x00),
                playerBetAmount: 0,
                hand: Hand.rock,
                playerStatus: PlayerStatus.STATUS_PENDING
            })

        });

        roomNum = roomLen; // 현재 방 번호를 roomNum에 할당시켜 반환
        roomLen = roomLen+1;


        return roomNum;

        // Emit gameCreated(msg.sender, msg.value);
    }

    //방에 참가하기
    function joinRoom(uint roomNum, Hand _hand) public payable isVaildHand(_hand) {
        rooms[roomNum].taker = Player({
            addr: payable(msg.sender), // 참여자 주소(배팅에 대한 payable)
            hand: _hand,
            playerBetAmount: msg.value,
            playerStatus: PlayerStatus.STATUS_PENDING
        });

        //방에 배팅 금액 추가
        rooms[roomNum].betAmount += msg.value;
        compareHands(roomNum); // 방에 방장과 참가자가 존재 => 승패 확인 -> 결과에 따라 게임의 상태와 참여자들 상태 업데이트

    }

    // 승패 확인 -> 결과에 따라 게임의 상태와 참여자들 상태 업데이트
    function compareHands(uint roomNum) private { //방의 게임 상태(gameStatus)와 게임 참여자들 상태(playerStatus) 업데이트 할 것이기 때문에 roomNum 가져오기
        uint originator = uint8(rooms[roomNum].originator.hand); // 방장 뭐 냈는지(0,1,2)로 측정되기 때문에 메모리 절약상 제일 작고 양수 값인 uint8
        uint taker = uint8(rooms[roomNum].taker.hand); // 참여자 뭐 냈는지

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED; // 게임 시작

        if(taker == originator) { // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE; // 방장 게임 상태 비김
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE; // 참여자 게임 상태 비김
        }  
        else if((taker + 1) % 3 == originator) { // 방장이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN; // 방장 게임 상태 이김
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE; // 참여자 게임 상태 짐          
        } 
        else if((originator + 1) % 3 == taker) { // 참여자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE; // 방장 게임 상태 짐
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN; // 참여자 게임 상태 이김        
        } 
        else { // 그 외 에러 -> 방장, 참여자 게임 상태는 계속 팬딩
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }


    }

    //방마다 배팅 금액 확인
    function checkTotalPay(uint roomNum) public view returns(uint roomNumPay) {
        return rooms[roomNum].betAmount;
    }

    //payout이 퍼블릭인데 해당 방의 방장 또한 참가자가 실행해야 함 => payout 함수 실행 전 유효성 검사
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    //배팅 금액 송금 하기
    function payout(uint roomNum) public payable isPlayer(roomNum,msg.sender) {
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) { // 둘 다 비긴 경우
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount); // 본인이 배팅한 금액 가져감
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount); // 본인이 배팅한 금액 가져감
        } else { // 비기지 않은 경우
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) { // 방장이 이긴 경우
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount); // 방에 배팅된 금액을 방장에게 전송
            } else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) { // 참여자가 이긴 경우
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount); // 방에 배팅된 금액을 참여자에게 전송
            } else { // error로 인한 pending 상태일 경우 
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount); // 본인이 배팅한 금액 가져감
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount); // 본인이 배팅한 금액 가져감
            }

        }

        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임 완료

    }

    //몇 명의 플레이어가 해당 방에 참여했는지 확인하는 기능
    function checkPlayerNum(uint roomNum) public view returns (uint playerNum) {
        
        if(rooms[roomNum].originator.addr == payable(0x00)) { // 방장도 없는 경우
            return 0;
        } else if(rooms[roomNum].originator.addr != payable(0x00)) { // 방장이 있는 경우
            if(rooms[roomNum].taker.addr == payable(0x00)) { // 참여자가 없는 경우
                return 1;
            } else { // 둘 다 있는 경우
                return 2;
            }

        }
    }

    //가장 배팅이 높은 방 알려주기
    function HighestBetAmountRoom() public view returns (uint roomNum) {
        uint highestRoomNum = 0;
        uint highestRoomBetAmount = rooms[0].betAmount;

        for(uint i=0;i<roomLen;i++) {   
            if(highestRoomBetAmount < rooms[i].betAmount) {
                highestRoomNum = i;
                highestRoomBetAmount = rooms[i].betAmount;
            }
        }   

        return highestRoomNum;
    }


}