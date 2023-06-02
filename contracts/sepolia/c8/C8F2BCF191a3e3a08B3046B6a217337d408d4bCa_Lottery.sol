/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Lottery {

    address public manager;
    address[] public playersList; 

    modifier onlyManager(){
        require(msg.sender == manager, "not owned");
        _;
    }

    constructor(){
        manager = msg.sender;     
    }

    function numberPlayers()public view returns(uint){
        return playersList.length;
    }    

    function getPlayersList()public view returns(address[] memory){
        return playersList;
    }

    function enterLottery()public payable{
        require(msg.value >= 1 ether,"min price 1 ether");
        playersList.push(msg.sender);
    }

    //generate a pseudo random number to pick a winner in the player array :
    function random()private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao,block.timestamp,playersList)));
    }

    function pickWinner() onlyManager public {
        uint index = random() % playersList.length;
        payable(playersList[index]).transfer(address(this).balance);
        delete playersList;
        
    }

}