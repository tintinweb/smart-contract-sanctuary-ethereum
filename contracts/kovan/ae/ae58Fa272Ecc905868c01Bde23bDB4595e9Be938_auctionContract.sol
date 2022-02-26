/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;


contract auctionContract{
    mapping ( address => uint ) public ticketBalance ;
    mapping ( address => bool ) public hasIncreased ; // True if has already increased init bid, false otherwise


    address author = msg.sender;
    address owner = msg.sender;
    address maxBidder; // address of the best current bid proposer
    string URL = "https://imgur.com/a/KHwbg9f";
    uint soldTickets = 0;
    uint initBid = 10;
    uint maxBid = 0;
    bool open = false;


    function buy(uint nbTickets) external payable {
        require (msg.value == nbTickets * (3 gwei));
        ticketBalance[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }


    function sell(uint nbTickets) external {
        require(ticketBalance[msg.sender] >= nbTickets);
        require(address(this).balance >= (nbTickets * (3 gwei)));
        ticketBalance[msg.sender] -= nbTickets;
        soldTickets -= nbTickets;
        payable (msg.sender).transfer(nbTickets * (3 gwei));    
    }


    function getOwner() external view returns (address){
        return owner;
    }


    function giveForFree(address a) external{
        require (owner == msg.sender);
        owner = a;
    }


    function getBalance() external view returns (uint) {
        return address(this).balance;
    }


    function newBid(uint nbTickets) external {
        require(ticketBalance[msg.sender] >= nbTickets);
        require(nbTickets > maxBid);
        require(nbTickets >= initBid);
        if(!open)
            open = true;
        ticketBalance[maxBidder] += maxBid; //The previous max bidder get back his bidded tickets
        ticketBalance[msg.sender] -= nbTickets; //Bidded tickets of new bidder got removed of his ticket balance 
        maxBidder = msg.sender;
        maxBid = nbTickets;
    }


    function getMaximalBid() external view returns (uint) {
        return maxBid;
    }


    function getMaximalBidder() external view returns (address) {
        return maxBidder;
    }


    function getMinimalPrice() external view returns (uint) {
        return initBid;
    }


    function increaseMinimalPrice() external {
        require(msg.sender == owner);
        require(hasIncreased[msg.sender] == false);
        initBid += 10;
        hasIncreased[msg.sender] = true;
    }


    function closeAuction() external {
        require(open == true);
        require(maxBid >= initBid);
        ticketBalance[owner] += maxBid;
        owner = maxBidder;
        initBid = maxBid;
        open = false;
    }


    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()),
        (soldTickets*(3 gwei) >= this.getBalance()));
    }
}