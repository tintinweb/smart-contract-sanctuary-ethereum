//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Race{
    //manager is in charge of the contract 
    // address public manager;
    //new player in the contract using array[] to unlimit number 
    address[] public players;
    address public winner;
    uint private balance;
    
    //to call the enter function we add them to players
    function enter() public payable{
       winner = address(0);
        //each player is compelled to add a certain ETH to join
        require(msg.value > .01 ether,"not enough funds");
        players.push(msg.sender);
        balance+=msg.value;
        if(players.length == 2){

            pickWinner();
        }
    }
    //creates a random hash that will become our winner
    function random() private view returns(uint){
        return  uint (keccak256(abi.encode(block.timestamp,  players)));
    }
    function pickWinner() private  {
        //only the manager can pickWinner
        //require(msg.sender == manager);
        //creates index that is gotten from func random % play.len
        uint index = random() % players.length;
        //pays the winner picked randomely(not fully random)
        payable (players[index]).transfer(balance);
        winner = players[index];
        players = new address[](0);
        balance = 0;
        
        //empies the old lottery and starts new one
    }

   
}