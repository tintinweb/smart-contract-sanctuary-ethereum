/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: EtherWallet.sol

// A solidity program that functions as a crowdsourcing code.
// Anyone can pay in money into the code, but only the owner can withdraw

contract EtherWallet
{
    // Initialize an address for the owner of the contract
    address payable owner;

    // Also initialize the amount we have in our contract so as to keep record of the funding
    uint public amount;

    // setting locked = false for check in reentrance
    bool locked;

    // I would love to keep accounts of all that have contributed money to this contract
    // I am going to map each address to a value sent
    mapping(address => uint) donors;

    // Constructor, makes the deployer the owner of the contract by default.
    // This should run on a successful deploy
    constructor()
    {
        owner = payable(msg.sender);
    }


    // Declaring two modifiers
    // 1. One making sure to correct the reentrancyhack
    // 2. One to make sure that the owner can withdraw

    modifier OnlyOwnerCanWithdraw(address withdrawer)
    {
        require(withdrawer == owner, "Only the owner is allowed to withdraw.");
        _;
    }

    modifier NoReentrance()
    {
        require(!locked, "You cannot redo this action.");
        locked = true;
        _;
        locked = false;
    }



    // A function that deposits money into the wallet
    function Deposit() public payable
    {
        amount += msg.value;
        donors[msg.sender] += msg.value;
    }


    // withdrawa function
    function Withdraw() public payable OnlyOwnerCanWithdraw(msg.sender) NoReentrance
    {
        // check for the total balances
        require(address(this).balance > 0, "You have nothing yet on this contract.");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        amount = 0;
        // payable(msg.sender).transfer(address(this).balance);
        
        require(sent, "The money wasn't sent.");
    }
}