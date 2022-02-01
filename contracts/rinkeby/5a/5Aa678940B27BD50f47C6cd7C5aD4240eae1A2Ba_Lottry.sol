/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

contract Lottry{
address public manager;
  address[] public players;
  
     constructor ()  {
         manager = msg.sender;
     }
     function enter () public payable {   /// @dev Enters a player to the Lottry and the play have to send in some eth
        require( ///@dev Require that the player is not already in the Lottry and that the player is not the manager
            msg.value > .01 ether,
            "You have to send in  a Minimum of 0.01 ether to enter the lottery"
        );
          players.push(msg.sender);

     }
     function random() private view returns (uint){
       return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))); ///@dev Through abi. encodePacked() , Solidity supports a non-standard packed mode where: types shorter than 32 bytes are concatenated directly, without padding or sign extension.
     }
     function pickRandomWinner () public onlyManager{
        uint winner = random() % players.length;
        payable(players[winner]).transfer(address(this).balance);
        players = new address[](0);
     }
     modifier onlyManager{
       require(msg.sender == manager, ///@dev This function is only available to the manager
       "Only the manager can call this function and pick a winner");
       _;
     }
     function getallPlayers() public view returns (address[] memory){
       return players;
     }
}