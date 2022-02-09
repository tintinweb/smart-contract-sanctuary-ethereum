/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

contract Auction{
    address public artwork;
    address public author = msg.sender;

    address public owner = msg.sender;

    uint public soldTickets = 0;
    uint public maxBid;
    address public maxBidder;
    uint public minPrice = 10;

    mapping (address => uint) public ticketBalance;

    mapping (address => string) identity;

    mapping (address => uint) bids;

    mapping (address => bool) increaseMinPrice;


    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
        
    function buy(uint nbTickets) external payable {
        require(msg.value == nbTickets * (3 gwei));
        ticketBalance[msg.sender]+= nbTickets;
        soldTickets += nbTickets;
    }
    
    function sell(uint nbTickets) external {
        require(nbTickets <= ticketBalance[msg.sender]);
        ticketBalance[msg.sender]-= nbTickets;
        payable(msg.sender).transfer(nbTickets *(3 gwei));
    }

    function getOwner () external view returns (address)
    {
        return owner;
    }
    
    function giveForFree (address a) external 
    {
        require (msg.sender == owner);
        owner = a;
               
    }

    function newBid (uint nbTickets) external
    {
        require(nbTickets <= ticketBalance[msg.sender]);
        if (nbTickets > maxBid)
        {
            maxBid = nbTickets;
            maxBidder = msg.sender;
        }
        
        bids[msg.sender] = nbTickets;

    }

    function getMaximalBid() external view returns (uint)
    {
        return maxBid;
    }

    function getMaximalBidder() external view returns (address)
    {
        return maxBidder;
    }

    function getMinimalPrice() external view returns (uint)
    {
        return minPrice;
    }

    function increaseMinimalPrice() external
    {
        require (!increaseMinPrice[msg.sender]);
        minPrice += 10;
        increaseMinPrice[msg.sender] = true;
    }

    function closeAuction () external
    {
        if (maxBid >= minPrice)
        {
            address tmp = owner;
            owner = maxBidder;
            
        }
    }

    function check() external view returns(bool,bool)
    {
        return( (soldTickets*(3 gwei) <= this.getBalance()),
                (soldTickets*(3 gwei) >= this.getBalance()));
    }

    
}