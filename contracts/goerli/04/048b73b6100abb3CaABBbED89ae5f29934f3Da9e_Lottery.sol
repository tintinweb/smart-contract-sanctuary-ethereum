/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract Lottery{
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    constructor(){
        owner = msg.sender;
        lotteryId = 0;
    }

    // Enter fuction to lottery
    function enter() public payable{
        require(msg.value >= 0.1 ether);
        players.push(payable(msg.sender));
    }

    // Get players 
    function getPlayers() public view returns (address payable[] memory){
        return players;
    }

    // Get balance 
    function getBalance()public view returns(uint){
        return address(this).balance;
    }

    // Get lottery id 
    function getLotteryId()public view returns(uint){
        return lotteryId;
    }

    // Get random numer 
    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner,block.timestamp)));
    }

    // Pick Winner
    function pickWinner() public {
        require(msg.sender == owner);
        uint randomIndex = getRandomNumber()%players.length;
        players[randomIndex].transfer(address(this).balance);
        winners.push(players[randomIndex]);
        lotteryId++;
        players = new address payable[](0);
    }

     // Get winners 
    function getWinners() public view returns (address[] memory){
        return winners;
    }
}