/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Lottery{
    address public accountAgency;
    address payable[] players;
    constructor(){
        accountAgency = msg.sender;
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    function buyLottery() public payable{
        require(msg.value == 1 ether, "Can buy lottery 1 ETH.");
        players.push(payable(msg.sender));
    }
    function getLength() public view returns(uint){
        return players.length;
    }
    function randomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    function selectWinner() public{
        require(msg.sender == accountAgency, "Unauthorized.");
        require(getLength() > 2, "Less then 2 players.");
        uint selectedNumber = randomNumber();
        address payable winner;
        uint index = selectedNumber % players.length;
        winner  =   players[index];
        winner.transfer(getBalance()); //transfer ether into winner
        players = new address payable[](0);
    }

}