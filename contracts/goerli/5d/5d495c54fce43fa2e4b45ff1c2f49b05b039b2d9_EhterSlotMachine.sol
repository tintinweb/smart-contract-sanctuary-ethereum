/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

//
//*********** Introduction of Ether Slot Machine **********************
//
//
// The ESM is a type of slot machine that runs on a blockchain. 
// It uses a smart contract, which is a set of rules encoded on 
// the blockchain that can be verified and audited.
//
// To access the ESM, a player needs the contract address and can
// find it on Etherscan Explore. Once they've found it, they can 
// deposit funds directly by transferring Ether to the contract address.
//
// The ESM has three main features:
// 
// 1. The Read Contract feature allows a player to check their account 
// balance by inputting their wallet address.
// 
// 2. The Write Contract feature enables a player to play the game by 
// connecting their wallet, inputting a bid amount in WEI, and clicking 
// the Write button to approve the gas fee. The results of the game can 
// be viewed under the transaction tab, which shows the bid amount, the
// new account balance, and whether the player won or lost.
//
// 3. The Withdraw feature allows a player to withdraw all their available
// balance by clicking the Write button and approving the gas fee.
// The ESM uses a random number generation logic that is based on time 
// and has a 45% chance of winning.
//
// Enjoy your bidding !!!!
//
// SPDX-License-Identifier: MIT
// V11: Developed from V10. Introdution was added. 
//
//
//************************************************************************

pragma solidity ^0.8.0;

contract EhterSlotMachine {
    address owner;
    mapping (address => uint256) balances;
    uint winChance; 
    
    constructor()  {
        owner = msg.sender;
        winChance = 45;     
    }

    receive() external payable
    {
        balances[msg.sender] += msg.value;
    }

    function Withdraw() external {
        require(balances[msg.sender] > 0, "Error.  Insufficient balance under your account.");
        require(address(this).balance >= balances[msg.sender], "Error. Insufficient balance under game.");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function Play(uint256 amount) public {    

        require(amount <= balances[msg.sender], "Error. Insufficient balance under your account.");
        require(amount <= balances[owner] / 20, "Error. Please reduce your PLAY amount.");

        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100 + 1;       

       if (randomNumber > winChance) {
            balances[msg.sender] -= amount;     
            balances[owner] += amount;
            emit BidLoss(msg.sender, "You Lose", amount, balances[msg.sender]);
        } else {          
            balances[msg.sender] += amount;      
            balances[owner] -= amount;
            emit BidWin(msg.sender, "You Win", amount, balances[msg.sender]);
        }
    }


    function Balance(address useraddress ) public view returns (uint256) {
        require(balances[useraddress] > 0, "Error.  Insufficient balance or account not exist.");
        return balances[useraddress];
    }


    event BidWin(address indexed bidder, string result, uint256 winAmount, uint256 balances);
    event BidLoss (address indexed bidder, string result, uint256 amount, uint256 balances);
}