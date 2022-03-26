/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-25

 Created by : Ghita Benkirane - Hasnae Bouhaddou - Imane Qorchi - Maxence Elfatihi
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6 <0.8.0;
pragma abicoder v2;

contract AuctionContract{

    mapping (address => uint) public ticketBalance;
    string url= "notrejolitoken";
    address author = 0xeA815Bd0E2F81A1e4fe37e899bB163AfB87a2163;
    address maximalBidder;
    uint maximalBid;
    uint minimalPrice = 10;
    mapping (address => bool) public hasChanged;
    uint public soldTickets = 0;

    
    function getOwner() external view returns(address){
        return author;
    }

    function giveForFree(address a) external{
        require(msg.sender == this.getOwner());
        author = a;
    }

    function check() external view returns(bool,bool){
        return( (soldTickets*(3 gwei) <= this.getBalance()),
                (soldTickets*(3 gwei) >= this.getBalance()));
    }

    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function increaseMinimalPrice() external{
        require(msg.sender == author);
        if (!hasChanged[msg.sender]){
            minimalPrice = minimalPrice + 10;
            hasChanged[msg.sender] = true;
        }
    }

    function buy(uint nbTickets) external payable{
        require(msg.value == nbTickets * (3 gwei));
        ticketBalance[msg.sender] = ticketBalance[msg.sender] + nbTickets;
    }
    
    function sell(uint nbTickets) external{
        require(nbTickets<= ticketBalance[msg.sender]);
        ticketBalance[msg.sender] = ticketBalance[msg.sender] - nbTickets;
        msg.sender.transfer(nbTickets*(3 gwei));
        soldTickets = soldTickets + nbTickets*(3 gwei);
    }
    

    function newBid(uint nbTickets) external{
        require(nbTickets<= ticketBalance[msg.sender]);
        require(nbTickets >= this.getMinimalPrice());
        if (nbTickets > this.getMaximalBid()) {
                maximalBidder = msg.sender;
                maximalBid = nbTickets;
            }
    }

    function getMaximalBid() external view returns(uint){
        return maximalBid;
    }

    function getMaximalBidder() external view returns(address){
        return address(maximalBidder);
    }

    function getMinimalPrice() external view returns(uint){
        return minimalPrice;
    }

    function closeAuction() external{
        if (this.getMaximalBid() >= this.getMinimalPrice()){
            ticketBalance[author] = ticketBalance[author] + this.getMaximalBid();
            ticketBalance[this.getMaximalBidder()] = ticketBalance[this.getMaximalBidder()] - this.getMaximalBid();
            author = this.getMaximalBidder();
            minimalPrice = this.getMaximalBid();
            msg.sender.transfer(this.getMaximalBid()*(3 gwei));
            soldTickets = soldTickets + this.getMaximalBid()*(3 gwei);
        }

    }

    
    
}