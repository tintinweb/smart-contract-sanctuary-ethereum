/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RPS {
    constructor () payable{} //송금 가능 컨트랙트임을 명시

    enum Hand{ // 가위, 바위, 보 enum => 플레이어는 이 외의 값을 가질 수 없다.
        rock,paper,scissors
    }

    enum PlayerStatus{ // 플레이어 상태
        STATUS_WIN,STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    struct Player { // 플레이어 구조체 선언
        address payable addr; // 주소
        uint256 playerbetAmount; // 베팅금액
        bytes32 hand; //가위 바위 보중에 뭘 냈는지 (해시값)
        PlayerStatus playerStatus; // 사용자의 현 상태   
        Hand dec_result; // 추가 : 디크립션 결과
    } 

     enum GameStatus{ // 게임 상태
        STATUS_NOT_STARTED,STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Game {
        Player originator; // 방장
        Player taker; // 참여자
        uint256 betAmount; // 총 베팅 금액
        GameStatus gameStatus; //게임의 현 상태
    }

    mapping(uint => Game) rooms; //rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식입니다.
    uint roomLen = 0; // rooms의 키 값, 방 생성될 때마다 1씩 올라감

    // modifier isValidHand (Hand _hand){ // 방장이 가위/바위/보 값을 제대로 지정했는지 확인하는 모디파이어
    //     require((_hand == Hand.rock)||(_hand == Hand.paper)||(_hand == Hand.scissors)); // createRoom 실행 시 확인
    //     _;
    // }

    // 인풋 데이터 해쉬를 위한 keccak 함수
    function keccak(Hand _hand, string memory _key) public pure returns(bytes32) {
    return keccak256(abi.encodePacked(_hand, _key));
    }

    //////게임 생성하기 - createRoom : commit phase
    // 베팅금액을 설정하기 대문에 payable
    function createRoom (bytes32 _hand) public payable returns (uint roomNum){ // 이제 인풋은 해쉬된 값이 들어옵니다.
        
        rooms[roomLen] = Game({    // 게임을 만들기 위해 rooms에 새로운 Game구조체 인스턴스 할당
            betAmount : msg.value,  // 아직 방장만 있어서 방장만 베팅 금액 넣음
            gameStatus : GameStatus.STATUS_NOT_STARTED, // 아직 시작하지 않은 상태

            originator : Player({  //방장
                hand : _hand, // byte32 해쉬된 인풋 추가
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerbetAmount : msg.value,
                dec_result : Hand.rock //일단 아무 값으로 초기화
            }),

            taker : Player({  //참여자
                hand : '0', // 일단은 임의 값으로 초기화
                addr : payable(msg.sender),  // 구조체 형식 초기화를 위해 일단 방장 주소로 할당
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerbetAmount : 0,
                dec_result : Hand.rock //일단 아무 값으로 초기화
            })
        });
        roomNum = roomLen; //리턴
        roomLen = roomLen +1; // 다음에 생성될 게임을 위해 방 번호 +1
    }

    ////// 게임 참가하기 - joinRoom : commit phase
    // 참가자는 참가할 방 번호, 자신이 낼 가위,바위,보 값을 인자로 보내고, 베팅금액은 msg.value로 설정
    // 가위 바위 보 값을 내기 때문에 마찬가지로 isValid 함수 제어자 사용

    function joinRoom (uint roomNum, bytes32 _hand) public payable {
        rooms[roomNum].taker = Player({
            hand : _hand, // byte32 해쉬된 인풋 추가
            addr : payable(msg.sender), // 참가자 주소로 변경
            playerStatus : PlayerStatus.STATUS_PENDING,
            playerbetAmount : msg.value, // 참가자 베팅 금액 설정
            dec_result : Hand.rock
        });

        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value; // 베팅 금액 업데이트
        compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }

    function revealOriginator(uint roomNum, Hand _hand, string memory key) public {
        require(msg.sender == rooms[roomNum].originator.addr); // 무조건 방장일 때에만 동작
        require(rooms[roomNum].originator.hand == keccak(_hand,key)); // 방장이 사전에 입력했던 해쉬값과, 지금 입력한 hand key를 이용한 해쉬값이 같아야 동작.
        rooms[roomNum].originator.dec_result = _hand; // 진짜 결과값 저장
    }

    function revealTaker(uint roomNum, Hand _hand, string memory key) public {
        require(msg.sender == rooms[roomNum].taker.addr); // 무조건 참가자일 때에만 동작
        require(rooms[roomNum].taker.hand == keccak(_hand,key)); // 참가자가 사전에 입력했던 해쉬값과, 지금 입력한 hand key를 이용한 해쉬값이 같아야 동작.
        rooms[roomNum].taker.dec_result = _hand; // 진짜 결과값 저장
    }
    // 게임 결과 업데이트 함수 
    function compareHands(uint roomNum) private{
        uint8 originator = uint8(rooms[roomNum].originator.dec_result);
        uint8 taker = uint8(rooms[roomNum].taker.dec_result);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;  // 게임상태 변경(게임시작)

        if(taker == originator) { // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }

        else if ((taker+1)%3 == originator){ // 방장 승리
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }

        else if((originator+1)%3 == taker){ // 참가자 승리
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        }

        else { // 그 외는 에러상태로 처리
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    modifier isPlayer (uint roomNum, address sender){ // 베팅 금액 송금 함수가 반드시 방장이나 참가자에 의해 실행되어야 함
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr); // 송신자 주소 확인을 통해 검증
        _;
    }

    // 베팅 금액 송금하는 함수
    function payout (uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){// 비긴 경우
            // 각자 자신이 낸 금액 돌려받음
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerbetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerbetAmount);
        }
        else{// 어느 한 쪽이 이긴 경우
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){ // 방장 승리
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }
            else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){ // 참가자 승리
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }
            else{ // 그 외의 경우(모종의 이유로 승리자 없을 때?)
               // 각자 자신이 낸 금액 돌려받음
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerbetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerbetAmount); 
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임 종료, 상태 변경
    }

}