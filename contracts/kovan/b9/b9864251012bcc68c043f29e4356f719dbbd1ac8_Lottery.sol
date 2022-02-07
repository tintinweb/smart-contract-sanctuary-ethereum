/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


/** 
 * @title Lottery
 * @dev Ether lotery that transfer contract amount to winner
*/  
contract Lottery {
    
    //list of players registered in lotery
    address payable[] public players;
    address public owner;
    uint public playersCount = 0;
    
    /**
     * @dev makes 'admin' of the account at point of deployement
     */ 
    constructor() {
        owner = msg.sender;
        //automatically adds admin on deployment
        players.push(payable(owner));
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }
    
    
    /**
     * @dev requires the deposit of 0.1 ether and if met pushes on address on list
     */ 
    receive() external payable {
       
        require(msg.sender != owner);
        
        // pushing the account conducting the transaction onto the players array as a payable adress
        players.push(payable(msg.sender));
        playersCount ++;
    }
    
    /**
     * @dev gets the contracts balance
     * @return contract balance
    */ 
    function getBalance() public view returns(uint){
        // returns the contract balance 
        return address(this).balance;
    }
    

    /** 
     * @dev picks a winner from the lottery, and grants winner the balance of contract
     */ 
    function pickWinner() private {

        //makes sure that we have enough players in the lottery  
        require(playersCount == 3);
        
        address payable winner;
    
        //transfers balance to winner
        winner.transfer( (getBalance() * 90) / 100); //gets only 90% of funds in contract
        payable(owner).transfer( (getBalance() * 10) / 100); //gets remaining amount AKA 10% -> must make admin a payable account
        
        
        //resets the plays array once someone is picked
       resetLottery(); 
        
    }
    
    /**
     * @dev resets the lottery
     */ 
    function resetLottery() internal {
        players = new address payable[](0);
    }

}