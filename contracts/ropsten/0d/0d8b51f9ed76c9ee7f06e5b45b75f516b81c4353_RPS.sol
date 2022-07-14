/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RPS {
    constructor () payable {}

    enum Hand{
        rock,paper,scissors
    }

    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    struct Player {
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        bytes32 hashedHand;
        PlayerStatus playerStatus;
    }

    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }

    struct Game {
        Player originator;
        Player taker;
        uint256 joined;
        uint256 betAmount;
        GameStatus gameStatus;
        bytes32 key;
    }

    mapping(uint256 => Game) rooms;
    uint256 roomLen = 0;



    modifier isValidHand (Hand _hand){
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors),"You Must Choose One Of [Rock, Scissors, Paper]");
        _;
    }

    function hashHand(Hand _hand, string memory _key) public pure isValidHand(_hand) returns (bytes32) {
            return keccak256(abi.encodePacked(_hand,_key));
    }

    function createRoom (bytes32 _hashedHand) public payable returns(uint256 roomNum){
        bytes32 hashedkey = keccak256('1');
        rooms[roomLen] = Game({
            key: hashedkey,
            joined: 1,
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: Hand.rock,
                hashedHand: _hashedHand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({
                hand: Hand.rock,
                hashedHand: '0',
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;   
        roomLen = roomLen+1;
    }

    function joinRoom(uint256 roomNum, Hand _hand) public payable isValidHand(_hand) {
        require(rooms[roomNum].gameStatus==GameStatus.STATUS_NOT_STARTED);
        rooms[roomNum].taker = Player({
            hand: _hand,
            hashedHand: '0',
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].joined = 2;
        rooms[roomNum].betAmount = rooms[roomNum].betAmount+msg.value;
    }

    function compareHands(uint256 roomNum) private {
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;

        if (taker==originator){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }
        if ((taker+1)%3 == originator){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        if ((originator+1)%3 == taker){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else{
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    function checkTotalPay(uint256 roomNum) public view returns(uint256 roomNumPay){
        return rooms[roomNum].betAmount;
    }

    function checkTotalPlayers(uint256 roomNum) public view returns(uint256 roomNumPay){
        return rooms[roomNum].joined;
    }

    function getRoomNum() public view returns(uint256){
        return roomLen;
    }

    function getRoomStatus(uint256 roomNum) public view returns(GameStatus){
        return rooms[roomNum].gameStatus;
    }

    function getBestPayRoom() public view returns(uint256){
        uint256 maxRoom = 0;
        uint256 maxPay = 0;
        for(uint256 i =0;i<roomLen;i++){
            uint256 amount = checkTotalPay(i);
            if(amount>maxPay){
                maxPay=amount;
                maxRoom=i;
            }
        }
        return maxRoom;
    }

    modifier isPlayer (uint256 roomNum, address sender){
        require(sender==rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    function verifyOriginator(Hand _hand, string memory _key, uint256 roomNum) private returns(bool) {
        require(msg.sender == rooms[roomNum].originator.addr);
        if(hashHand(_hand, _key) == rooms[roomNum].originator.hashedHand){
            rooms[roomNum].originator.hand = _hand;
            return true;
        }
        else { return false; }
        
    }

    function getOriginatorHand(string memory _key, uint256 roomNum) private{
        if(verifyOriginator(Hand.rock,_key,roomNum)){
            return;
        }
        if(verifyOriginator(Hand.scissors,_key,roomNum)){
            return;
        }
        verifyOriginator(Hand.paper,_key,roomNum);
    }

    function payout(string memory _key, uint256 roomNum) public payable isPlayer(roomNum,msg.sender) returns (string memory result) {

        getOriginatorHand(_key,roomNum);
        compareHands(roomNum);

        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            result = "TIE";
        }else{
            if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
                result = "originator WIN";
            } else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN){
                rooms[roomNum].taker.addr.transfer(rooms[roomLen].betAmount);
                result = "taker WIN";
            } else{
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
                result = "ERROR";
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}