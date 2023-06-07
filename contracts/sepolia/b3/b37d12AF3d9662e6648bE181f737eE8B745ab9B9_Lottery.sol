/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract Lottery {

     address public Manager; //Owner of the lottery system
     address payable[] public participants; 
     uint256 public no_of_Lotteries; //no of lotteries sold
     mapping(uint=> address)public Winners; //Permanently store winners in mapping
     uint256 public Winners_Count = 0;         //no of winners
     uint256 amount;
     address payable winner;
    
constructor(){
    Manager = msg.sender;
    }

function BuyLottery()public payable {
    require(msg.value == 1 wei,"minimum entry price is one ether");
    participants.push(payable(msg.sender));
    no_of_Lotteries++;
}

function getBalance() public view returns(uint){
    require(msg.sender == Manager, "only manager can see balance");
    return address(this).balance;
}

 //to get random number i use the technique 
 //block.difficulty + block.timestamp + participants.length and pack them together by
 // using abi encoding scheme 
 //and then generate a hash after that convert that particular hash into integer format  

function Random() public view returns(uint){
    
 return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));

}

function choose_winner() public returns(address,uint256){
    require(msg.sender == Manager,"only Manager can choose winner");
    require(participants.length >= 3,"you can only choose winner after 3 members");
    amount = getBalance();
    uint r = Random();
    uint index = r % participants.length;
    winner = participants[index];
    winner.transfer(amount);
    Winners_Count += 1;
    Winners[Winners_Count] = winner;      //Winner's mapping
    participants = new address payable[](0); //clear array for new Lottery
    no_of_Lotteries = 0;
    return(winner,amount);
    
}
}