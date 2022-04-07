/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
// https://ropsten.etherscan.io/address/0x6fe972bae9007c2c0f8329b028a636f806644210#code

pragma solidity ^0.8.7;

contract RPS {
    constructor () payable {}
    
    /*
    event GameCreated(address originator, uint256 originator_bet);
    event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event OriginatorWin(address originator, address taker, uint256 betAmount);
    event TakerWin(address originator, address taker, uint256 betAmount);
   */
   
    enum Hand {
        rock, paper, scissors
    }
    
    enum PlayerStatus{
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player {
        // Hand hand;        
        uint hand;
        address payable addr;
        PlayerStatus playerStatus;
        uint256 playerBetAmount;
    }
    
    struct Game {
        uint256 betAmount;
        GameStatus gameStatus;
        Player originator;
        Player taker;
    }
    
    
    mapping(uint => Game) rooms;
    uint roomLen = 0;
    uint hashedHand;
    
    modifier isValidHand (Hand _hand) {
        require((_hand  == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors));
        _;
    }
    
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    // BetAmount가 같은지 확인
    modifier isSameBetAmount(uint roomNum, uint value) {
        require(rooms[roomNum].originator.playerBetAmount == value);
        _;
    }

    // 이미 Taker가 존재하는지 확인
    modifier isExistTaker(uint roomNum) {
        require(rooms[roomNum].taker.playerBetAmount == 0);
        _;
    }

    modifier encryptoHand(Hand _hand, address sender) {
        hashedHand = uint(keccak256(abi.encodePacked(uint(_hand), '1', sender)));
        _;
    }
    
    function createRoom (Hand _hand) public payable isValidHand(_hand) encryptoHand(_hand, msg.sender) returns (uint roomNum) {

        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                // hand: _hand,
                hand: hashedHand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({ // will change
                // hand: Hand.rock,
                hand: uint(0),
                addr: payable(msg.sender),  
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen;
        roomLen = roomLen+1;
        
        
       // Emit gameCreated(msg.sender, msg.value);
    }
    
    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand( _hand) isSameBetAmount(roomNum, msg.value) isExistTaker(roomNum) encryptoHand(_hand, msg.sender) {
        // Emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);        
        rooms[roomNum].taker = Player({
            // hand: _hand,
            hand: uint(hashedHand),
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum);
    }
    
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
         rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
    
    function compareHands(uint roomNum) private{        
        uint originatorH = uint(rooms[roomNum].originator.hand);
        uint takerH = uint(rooms[roomNum].taker.hand);
        uint8 originator;
        uint8 taker;

        for (uint i = 0; i <= 2; i++) {
            if (encryptoHand2(i, rooms[roomNum].originator.addr) == originatorH) {
                // originatorHand = i;
                originator = uint8(i);
            }
        }

        for (uint i = 0; i <= 2; i++) {
            if (encryptoHand2(i, rooms[roomNum].taker.addr) == takerH) {
                // originatorHand = i;
                taker = uint8(i);
            }
        }
                
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        
        if (taker == originator){ //draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((taker +1) % 3 == originator) { // originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%3 == taker){
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;   
        }       
    }

    function encryptoHand2(uint _hand, address sender) private returns (uint){
        return uint(keccak256(abi.encodePacked(uint(_hand), '1', sender)));
    }

}