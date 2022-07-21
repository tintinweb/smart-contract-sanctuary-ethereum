/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// File: contracts/New.sol


pragma solidity ^0.8.0;

contract HouseWallet{
    address private admin;
    uint256 gameId;
    mapping(address=> uint256) public gameIdplayer;

   struct WinGame{
        uint256 id;
        uint256 bet;
        address payable player;
    }

    WinGame []  wingames; 


    constructor(){
        admin = msg.sender;
        gameId=0;
    }

    function recived(uint256 _amount) public payable {      
        WinGame memory e = WinGame(gameId, _amount, payable(msg.sender));
        wingames.push(e);
        gameId = gameId+1; 
    }

    function claimReward (bool _stat, uint256 _Id, address _player) external{
       require(_stat == true,'Error,');
       uint i;
        for(i=0; i<wingames.length; i++)
       {
           WinGame memory e = wingames[i];
          if(e.id==_Id && e.player==_player){
           e.player.transfer(e.bet);
          }
          
       }
    }

    
}