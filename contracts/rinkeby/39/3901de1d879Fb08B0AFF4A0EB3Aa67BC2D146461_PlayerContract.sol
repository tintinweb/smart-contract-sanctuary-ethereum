/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract PlayerContract {

  uint public playerCount;

  struct Player
  {
    string name;
    uint level;
    uint highestScore;
  }    

  mapping(uint => Player) public player;
   
  /**
    * @dev addPlayer is used to add the player.
    * @param name - name 
    * @param level - level of the player
    * @param highestScore - highestScore of the player
  */ 
  function addPlayer(string memory name,uint level,uint highestScore)
  public
  {
    player[playerCount] = Player(name,level,highestScore);
    playerCount++;
  }

  /**
    * @dev getAllPlayer is used to get the all players.
  */ 
  function getAllPlayer()
  public
  view
  returns(Player[] memory)
  {

   Player[] memory playerRecord = new Player[](playerCount);

    for(uint i=0; i<playerCount; i++){
      playerRecord[i] =  player[i];
    }

    return playerRecord;
  }  

  function getPlayer(uint playerID)
  public
  view
  returns(Player memory)
  {
    return player[playerID];
  } 

}