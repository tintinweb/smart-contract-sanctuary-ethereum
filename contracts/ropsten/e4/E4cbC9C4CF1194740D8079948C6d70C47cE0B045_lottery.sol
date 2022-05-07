/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract lottery{
    address  manager;
    address payable[] players;

    constructor(){
        manager = msg.sender;
    }
    function getBalance() public view returns(uint){
            return address(this).balance;
    }
    function buyLottery() public payable{
        require(msg.value == 0.1 ether,"Please buy Lottery 0.1 ETH only");
        players.push(payable(msg.sender));
    }
    function getLength() public view returns(uint){
            return players.length;
    }
    function randomNumber() public view returns(uint){
            return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,players.length)));
    }
    function selectWinner() public {
            require(msg.sender == manager,"No permission");
            require(getLength() >= 2,"Need morethan 2 players");
            uint pickrandom = randomNumber();
            uint selectindex = pickrandom % players.length;
            address payable winner;
            winner = players[selectindex];
            winner.transfer(getBalance()); // Transfer
            players = new address payable[](0);
            
    }
}