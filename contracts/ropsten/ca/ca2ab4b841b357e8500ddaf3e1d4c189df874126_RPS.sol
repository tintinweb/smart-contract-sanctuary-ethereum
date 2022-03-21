/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // 0.8.7 이상

contract RPS{
    //contract 가 이더를 받을 수 있도록 설정
    constructor () payable {}

    //# 사용자와 게임 구조체 생성
    enum eHand {
        rock,       //바위 : 0
        paper,      //보   : 1
        scissors    //가위 : 2
    }

    enum ePlayerState{
        STATE_WIN,     //승리
        STATE_LOSE,    //패배
        STATE_TIE,     //무승부
        STATE_PENDING  //대기상태
    }

    // 게임 방의 상태
    enum eGameState{
        STATE_NOT_STARTED,  //방을 만들어둔 상태
        STATE_STARTED,      //참여자가 참여하여 게임 결과가 나온 상태
        STATE_COMPLETE,     //게임 결과에 따라 베팅금액을 분배한 상태
        STATE_ERROR         //게임 도중 에러 발생상태
    }

    struct fPlayer{
        address payable addr; // 주소
        uint256 playerBetAmount; //배팅금액, 최대 16진수 16자리
        eHand hand; //플레이어가 낸 가위/바위/보 값
        ePlayerState playerState; // 사용자의 현 상태
    }

    struct fGame{
        fPlayer gameHost;       // 방장 정보
        eGameState gameState;   // 게임상태
        fPlayer gameChallenger; // 게임 도전자
        uint256 betAmount;      // 총 베팅금액
    }

    mapping(uint => fGame) rooms; // room[0], rooms[1] 형식으로 접근할 수 있으며
    uint roomLen = 0; // rooms 의 키 값입니다. 방이 생성될때마다 1씩 올라갑니다.


    //#  게임 생성

    // 방 만들기 전에, _hand 에 올바른값 ( 가위 , 바위 , 보 ) 를 넣었는지 체크
    modifier isValidHand (eHand _hand){
        require((_hand == eHand.rock) || (_hand == eHand.paper) || (_hand == eHand.scissors));
        _; // 윗줄은, 함수가 되기 전 실행
    }

    function createRoom (eHand _hand) public payable isValidHand(_hand) returns (uint roomNum){
        // 이더를 받을 수 있는 함수
        // 배팅금액을 설정하기 때문에 payable 키워드를 사용합니다
        // 변수 roomNum 값을 반환합니다. return 대신 roomNum = 값 으로 반환할 수 있습니다.

        rooms[roomLen] = fGame({
            betAmount : msg.value,
            gameState : eGameState.STATE_NOT_STARTED,
            gameHost : fPlayer({
                hand : _hand,
                addr : payable(msg.sender),
                playerState : ePlayerState.STATE_PENDING,
                playerBetAmount : msg.value
            }),
            gameChallenger: fPlayer({
                hand : eHand.rock,
                addr : payable(msg.sender),
                playerState : ePlayerState.STATE_PENDING,
                playerBetAmount : 0
            })
        });
        roomNum = roomLen; // roomNum 은 리턴된다. 현재 방 번호를 roomNum 에 할당시켜 반환
        roomLen = roomLen+1; // 다음 방 번호를 설정
    }

    function joinRoom (uint roomNum, eHand _hand) public payable isValidHand(_hand){
        // 방 넘버에 해당하는 게임 방의 gameChallenger 를 설정
        rooms[roomNum].gameChallenger = fPlayer({
            hand : _hand,
            addr : payable(msg.sender),
            playerState : ePlayerState.STATE_PENDING,
            playerBetAmount : msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value; // 방에 있는 금액과 도전자의 금액을 합쳐서 방의 금액에 넣어
        
        // 참가자가 다 모였으니, 게임결과 업데이트 함수 호출
        compareHands(roomNum);
    }

    function compareHands(uint roomNum) private{
        uint8 gameHostHand = uint8(rooms[roomNum].gameHost.hand); // 방장 손
        uint8 gameChallengerHand = uint8(rooms[roomNum].gameChallenger.hand);        // 도전자 손

        rooms[roomNum].gameState = eGameState.STATE_STARTED;  // 게임은 시작되었다

        if(gameChallengerHand == gameHostHand){ // 비긴경우
            rooms[roomNum].gameHost.playerState = ePlayerState.STATE_TIE;
            rooms[roomNum].gameChallenger.playerState = ePlayerState.STATE_TIE;
        }
        else if((gameChallengerHand + 1)%3 == gameHostHand ){ // 이긴사람이 방장이다.
            rooms[roomNum].gameHost.playerState = ePlayerState.STATE_WIN;
            rooms[roomNum].gameChallenger.playerState = ePlayerState.STATE_LOSE;
        }
        else if((gameHostHand +1)%3 == gameChallengerHand ){ // 이긴사람이 도전자다
            rooms[roomNum].gameHost.playerState = ePlayerState.STATE_LOSE;
            rooms[roomNum].gameChallenger.playerState = ePlayerState.STATE_WIN;            
        }else{  // 그 외의 상황에는 게임 상태를 에러로 업데이트 한다
            rooms[roomNum].gameState = eGameState.STATE_ERROR;
        }
    }

    modifier isPlayer(uint roomNum, address senderAddr){
        require( senderAddr == rooms[roomNum].gameHost.addr || senderAddr == rooms[roomNum].gameChallenger.addr); // 호출한사람이 참가자중 한명이어야 합니다
        _; //함수실행
    }

    // payout 을 호출하는 주체는 isPlayer 함수를 통해 참가자중 한명인지 검증후 함수가 실행됩니다.
    function payout(uint roomNum) public payable isPlayer(roomNum,msg.sender){
        if(rooms[roomNum].gameHost.playerState == ePlayerState.STATE_TIE && rooms[roomNum].gameChallenger.playerState == ePlayerState.STATE_TIE)
        {   // 비긴경우
            rooms[roomNum].gameHost.addr.transfer(rooms[roomNum].gameHost.playerBetAmount); // 방장은 방장이 낸 돈 돌려받고
            rooms[roomNum].gameChallenger.addr.transfer(rooms[roomNum].gameChallenger.playerBetAmount); // 도전자는 도전자가 낸 돈 돌려받고
        }
        else {  // 승부가 난 경우

            if(rooms[roomNum].gameHost.playerState == ePlayerState.STATE_WIN)
            {   // 방장이 이긴경우
                rooms[roomNum].gameHost.addr.transfer(rooms[roomNum].betAmount); // 방장이 방의 돈 다가져
            }
            else if (rooms[roomNum].gameChallenger.playerState == ePlayerState.STATE_WIN)
            {   // 도전자가 이긴경우
                rooms[roomNum].gameChallenger.addr.transfer(rooms[roomNum].betAmount);    // 도전자가 방의 돈 다가져
            }
            else{
                rooms[roomNum].gameHost.addr.transfer(rooms[roomNum].gameHost.playerBetAmount); // 방장은 방장이 낸 돈 돌려받고
                rooms[roomNum].gameChallenger.addr.transfer(rooms[roomNum].gameChallenger.playerBetAmount); // 도전자는 도전자가 낸 돈 돌려받고
            }
        }
    }


}