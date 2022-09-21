/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier : MIT
pragma solidity >=0.7.0 <0.9.0;

contract RPS{
    
    enum Hand{rock, paper, scissors}
    //플레이어의 상태
    enum PlayerStatus{st_win, st_lose, st_same, st_pending}
    //게임의 상태
    enum GameStatus{game_notStarted, game_playing, game_end, game_error}
    
    //플레이어 빌드
    struct Player {
        //어드레스
        address payable addr;
        //hand
        Hand hand;
        //베팅값
        uint256 betAmount;
        //플레이어 상태
        PlayerStatus playerStatus;
        // 구조에 대한 변수선언 

    }
    //방에 대한 빌드
    struct Game{
        //플레이어 방장
        Player master;
        //플레이어 플레이어
        Player guest;
        //totalbetAmount
        uint256 totalBetAmount;
        //게임의 상태
        GameStatus gameStatus;
    }

    mapping(uint256 => Game) rooms;
    uint256 roomLength = 0;
    modifier isValid(Hand _hand){
        require((_hand == Hand.rock)|| (_hand == Hand.paper)||(_hand == Hand.scissors));
        _;
    }
    modifier isPlayer(uint roomNum, address sender){
        require((sender == rooms[roomNum].master.addr || sender == rooms[roomNum].guest.addr));
        _;
    }

    //createRoom -> 방장이 만들떄 변수로는 방장 hand, amount(msg.value)  return roomnum 
 function createRoom(Hand _hand) public payable isValid(_hand) returns(uint roomNum){
     

    rooms[roomLength] = Game({
        master : Player({
            addr : payable(msg.sender),
            hand : _hand,
            betAmount : msg.value,
            playerStatus : PlayerStatus.st_pending
        }),
        guest : Player({
            addr : payable(msg.sender),
            hand : Hand.rock,
            betAmount : 0,
            playerStatus :PlayerStatus.st_pending
        }),
        totalBetAmount : msg.value,
        gameStatus : GameStatus.game_notStarted
    });
     roomNum=roomLength;
            roomLength = roomLength+1;

 }
 function joinRoom(uint roomNum, Hand _hand) public payable isValid(_hand){

     rooms[roomNum].guest =Player({
         hand : _hand,
         addr : payable(msg.sender),
         playerStatus : PlayerStatus.st_pending,
         betAmount : msg.value
     });
    rooms[roomNum].totalBetAmount = rooms[roomNum].totalBetAmount + msg.value;
    compareHands(roomNum);
    
 }
  function checkTotalPay(uint roomNum) public view returns(uint roomNumPay){
      return rooms[roomNum].totalBetAmount;
  }
 function compareHands(uint roomNum) private{
     uint256 master = uint8(rooms[roomNum].master.hand);
     uint256 guest = uint8(rooms[roomNum].guest.hand);

     rooms[roomNum].gameStatus = GameStatus.game_notStarted;

     if(guest == master){
         rooms[roomNum].master.playerStatus = PlayerStatus.st_same;
         rooms[roomNum].guest.playerStatus = PlayerStatus.st_same;
     }
     if((guest+1)%3 == master){
         rooms[roomNum].master.playerStatus = PlayerStatus.st_win;
         rooms[roomNum].guest.playerStatus = PlayerStatus.st_lose;
     }
      if((master+1)%3 == guest){
         rooms[roomNum].guest.playerStatus = PlayerStatus.st_win;
         rooms[roomNum].master.playerStatus = PlayerStatus.st_lose;
     }

     else{
         rooms[roomNum].gameStatus = GameStatus.game_error;
     }
 }

 function payout(uint roomNum) public payable isPlayer(roomNum,msg.sender){
     if(rooms[roomNum].master.playerStatus == PlayerStatus.st_same){
         rooms[roomNum].master.addr.transfer(rooms[roomNum].master.betAmount);
         rooms[roomNum].guest.addr.transfer(rooms[roomNum].guest.betAmount);
     }
     else{
         if(rooms[roomNum].master.playerStatus == PlayerStatus.st_win){
             rooms[roomNum].master.addr.transfer(rooms[roomNum].totalBetAmount); 
         }
         if(rooms[roomNum].guest.playerStatus == PlayerStatus.st_win){
             rooms[roomNum].guest.addr.transfer(rooms[roomNum].totalBetAmount); 
         }
         else{
         rooms[roomNum].master.addr.transfer(rooms[roomNum].master.betAmount);
         rooms[roomNum].guest.addr.transfer(rooms[roomNum].guest.betAmount);
   }
     }
        rooms[roomNum].gameStatus = GameStatus.game_end;
 }
        
}