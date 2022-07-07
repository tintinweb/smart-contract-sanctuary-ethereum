/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;

contract Lottery {  
    address Owner;
    
    constructor() {
        Owner = msg.sender;
    }
    
    address Winner;

    enum  LotteryState { OPEN, CLOSED }
    LotteryState CurrentState;

    // Creates list of lottery contestants
    address[] private entries;

    // Enters a new contestant into the lottery via entries array. Checks if the lottery is open 
    // and if the new contestant has already been entered.
    function EnterLottery() public payable {
        require(CurrentState == LotteryState.OPEN, "Lottery is closed.");
        require(msg.sender.balance >= 1e15, "Not Enough ETH.");
        bool Repeated;
        for(uint i = 0; i < entries.length; i++) {
            address addr = entries[i];
        // check if address is unique
            require(msg.sender != addr, "This address has already been entered.");
            Repeated = false;
        // if the address is not already list
        }   
        require(Repeated == false); //redudant
        payable(msg.sender).transfer(1e15);
        entries.push(msg.sender);    
    }

    function ViewContestants() public view returns(address [] memory){
        return entries;
    }

    function ViewJackpotTotal() public view returns(uint){
        uint Jackpot = address(this).balance;
        return Jackpot;
    }

    function RunLottery() public returns(address){
        require(msg.sender == Owner, "Cannot preform this action.");
        CurrentState = LotteryState.CLOSED;
        uint PsudoRand = entries.length % 1;
        Winner = entries[PsudoRand];
        return Winner;
    }

    function ViewWinners() public view returns(address) {
        require(CurrentState == LotteryState.CLOSED, "The winner has not been selected.");
        return Winner;
    }
    
    function PayWinner() public {
        require(msg.sender == Owner, "Cannot preform this action.");
        require(CurrentState == LotteryState.CLOSED, "The winner has not been selected.");
        address payable to = payable(Winner);
        to.transfer(address(this).balance);
        delete entries;
        CurrentState = LotteryState.OPEN;
        Winner = 0x0000000000000000000000000000000000000000;
    }
}