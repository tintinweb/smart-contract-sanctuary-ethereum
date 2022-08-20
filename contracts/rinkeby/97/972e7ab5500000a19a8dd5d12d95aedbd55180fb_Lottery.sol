/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottery{
    address manager;
    address payable[] players;

    constructor(){
        manager = msg.sender;
    }
    function getBalance() public view returns(uint){
            return address(this).balance;
    }
    function buyLottery() public payable{
        require(msg.value == 0.01 ether,"Please Buy Lottery 1 ETH Only");
        players.push(payable(msg.sender));
    }
    function getLength() public view returns(uint){
        return players.length;
    }
    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    function selectWinner() public{
        require(msg.sender == manager,"You can't Manager");
        require(getLength()>=2,"less then 2 players");
        uint pickrandom = randomNumber();
        address payable winner;
        uint selectIndex = pickrandom % players.length;
        winner = players[selectIndex];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }
}