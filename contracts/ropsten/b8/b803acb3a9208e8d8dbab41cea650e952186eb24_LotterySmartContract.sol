/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract LotterySmartContract {
     address payable [] public players;
     address public Manager;
     address payable public Winner;
    constructor(){
        Manager=msg.sender;
    }
     
    function participate() public payable {
        require(msg.value> 1 ether,"Your Balance is Not greater than 1");
        players.push(payable(msg.sender));
    }
    function showBalanc() public view returns (uint){
        require(Manager==msg.sender,"You are not Manager");
        return address(this).balance;
    }
    function random() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,players.length)));
    } //Random Number Generating
    function pickWinner() public{
        require(Manager==msg.sender,"You are not Manager");
        require(players.length>=3);
        uint ran = random();
        uint index=ran % players.length;
        Winner=players[index];
        Winner.transfer(showBalanc());
       players = new address payable [](0);
    }

}