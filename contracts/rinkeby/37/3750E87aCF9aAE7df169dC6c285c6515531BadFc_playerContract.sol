/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

contract playerContract {


  uint public playerCount;

  struct Player
  {
    string name;
    uint level;
    uint highestScore;
   }    

   mapping(uint => Player) private player;
   
   function addPlayer(
    string memory name,
    uint level,
    uint highestScore
    )
    public
    {
        player[playerCount] = Player(name,level,highestScore);
        playerCount++;
    }

    function getPlayer(
    uint playerID
    )
    public
    view
    returns(Player memory)
    {
       return player[playerID];
    }

    function getAllPlayer()
    public
    view
    returns(Player[] memory){

    Player[] memory playerRecord = new Player[](playerCount);

    for(uint i=0; i<playerCount; i++){
      playerRecord[i] =  player[i];
    }

    return playerRecord;
    }   
}