/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <=0.8.13;


contract Random{
    //manager is in charge of the contract 
    address public manager;
    //new player in the contract using array[] to unlimit number 
    string[] public players = ['a','b','c','d'];
    string public winner;
    uint public  winIndex;
    function lottery() public {
        manager = msg.sender;
    }
    //to call the enter function we add them to players
    function enter( string memory player) public {
        //each player is compelled to add a certain ETH to join
        players.push(player);
    }
    //creates a random hash that will become our winner
    function random(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }
    function pickWinner() public {
        //only the manager can pickWinner
        //require(msg.sender == manager);
        //creates index that is gotten from func random % play.len
        winIndex = random(players.length);
        //pays the winner picked randomely(not fully random)
        winner = players[winIndex];
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;

    }

}