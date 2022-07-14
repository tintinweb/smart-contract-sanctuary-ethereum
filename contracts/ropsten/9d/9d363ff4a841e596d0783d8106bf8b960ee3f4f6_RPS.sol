/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract RPS{
    constructor() payable{}

    enum Hand{
        rock, paper, scissors
    }

    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    enum GameStatus{
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Player{
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        // New code
        bytes32 hashHand;
        PlayerStatus playerStatus;
    }

    struct Game{
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus gameStatus;
        uint16 playerNum;
    }

    mapping(uint => Game) rooms;
    uint roomLen = 0;

    modifier isValidHand(Hand _hand){
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    modifier isPlayer(uint roomNum, address sender){
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }
    // new code;
    function keccak(uint256 _hand, string memory _key) public pure returns (bytes32) {
            return keccak256(abi.encodePacked(_hand,_key));
    }

    function verifyOriginator(uint256 _hand, string memory _key, uint roomNum) private returns(bool) {
        require(msg.sender == rooms[roomNum].originator.addr);
        if(keccak(_hand, _key) == rooms[roomNum].originator.hashHand){
            rooms[roomNum].originator.hand = Hand(_hand);
            return true;
        }
        else { return false; }
        
    }

    // input Data changed;
    function createRoom(bytes32 _hashHand) public payable returns(uint roomNum){
        rooms[roomLen] = Game({
            betAmount : msg.value,
            gameStatus : GameStatus.STATUS_NOT_STARTED,
            originator : Player({
                // New Code (hashHand)
                hashHand : _hashHand,
                hand : Hand.rock,
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmount : msg.value
            }),
            taker : Player({
                // New Code (hashHand)
                hashHand : 0,
                hand : Hand.rock,
                addr : payable(msg.sender),
                playerStatus : PlayerStatus.STATUS_PENDING,
                playerBetAmount : 0
            }),
            playerNum : 1
        });
        roomNum = roomLen;
        roomLen++;

    }

    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand(_hand){
        rooms[roomNum].taker = Player({
            // New Code (hashHand)
            hashHand : 0,
            hand : _hand,
            addr : payable(msg.sender),
            playerStatus : PlayerStatus.STATUS_PENDING,
            playerBetAmount : msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        rooms[roomNum].playerNum++;
        // compareHands(roomNum);
    }

    function compareHands(uint roomNum, uint256 _hand, string memory _key) public{

        // New Code
        // Hash(_hand, _key) 값을 확인한다
        require(verifyOriginator(_hand, _key, roomNum) == true, "wrong Hash");

        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if(taker == originator){
            // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }else if((taker + 1) % 3 == originator){
            // originator이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }else if((taker + 1) % 3 == originator){
            // originator이 패배한 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        }else{
            // 예외 경우
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
        payout(roomNum);
    }

    // ToalPay Check 함수
    function checkTotalPay(uint roomNum) public view returns(uint roomNumPay){
        return rooms[roomNum].betAmount;
    }

    // BetAmount가 가장 많은 방 출력
    function checkMaxBetRoom() public view returns(uint8 MaxBetRoom){
        uint8 max = 0;
        uint8 maxBetRoom = 0;
        for(uint8 i=0; i<roomLen; i++){
            if(rooms[i].betAmount > max){
                max = uint8(rooms[i].betAmount);
                maxBetRoom = i;
            }
        }
        return maxBetRoom;
    }

    // 특정 방의 플레이서 수 계산
    function checkNumOfPlayer(uint roomNum) public view returns(uint numOfPlayers){
        return rooms[roomNum].playerNum;
    } 

    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender){
        // 비긴 경우
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        }else{
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            }else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            }else{
                // 오류가 발생하는 경우 베팅 금액 환불
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
            rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
        }
    }
}