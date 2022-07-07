//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Race{
    //manager is in charge of the contract 
    // address public manager;
    //new player in the contract using array[] to unlimit number 
    address[] public players;
    address public winner;
    
    //to call the enter function we add them to players
    function enter() public payable{
       winner = 0x0000000000000000000000000000000000000000;
        //each player is compelled to add a certain ETH to join
        require(msg.value > .01 ether,"not enough funds");
        players.push(msg.sender);
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
        payable (players[index]).transfer(address(this).balance);
        players = new address[](0);
        winner = players[index];
        
        //empies the old lottery and starts new one
    }

   
}