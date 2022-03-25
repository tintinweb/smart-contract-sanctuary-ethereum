/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: GPL-3.0
// Developed by Adrien Girard

contract AuctionContract{
address public creator = msg.sender;
address public owner=msg.sender;
string public URL = "http://...";
uint public soldTickets=0;
mapping (address => uint) public ticketBalance;
uint maximalbid=0;
uint minimalbid=10;
address maximalBidder=msg.sender;
mapping (address => uint) public minimalbidchanged;

function giveForFree(address a) external {
    if (msg.sender == owner) {
        owner=a;
    }
}

function buyTickets(uint nbTickets) external payable {
        require(msg.value == nbTickets * (3 gwei));
        ticketBalance[msg.sender]+= nbTickets;
        soldTickets+=nbTickets;

}

function sell(uint nbTickets) external {
        require(nbTickets<= ticketBalance[msg.sender]);
        ticketBalance[msg.sender]-= nbTickets;
        payable(msg.sender).transfer(nbTickets*(3 gwei));
        soldTickets-=nbTickets;
}


function getOwner() external view returns (address a){
    return owner;
}

function getBalance() external view returns(uint balance){
    return ticketBalance[msg.sender];
}

function newBid(uint nbTickets) external {
    if (nbTickets <= ticketBalance[msg.sender]){
    if (nbTickets >= minimalbid){
        if(nbTickets > maximalbid){}
        maximalbid=nbTickets;
        maximalBidder=msg.sender;
    }
    }
    }


function getMaximalBid() external view returns(uint max){
    return maximalbid;
}

function getMaximalBidder() external view returns(address max){
    return maximalBidder;
}

function getMinimalPrice() external view returns (uint min){
    return minimalbid;
}

function increaseMinimalPrice(uint nbTickets) external{
    if (minimalbidchanged[msg.sender]==0){
        if (nbTickets > minimalbid){
            minimalbid += nbTickets;
            minimalbidchanged[msg.sender]++;
            
    }
    }
}

function closeAuction() external{
    ticketBalance[maximalBidder]-=maximalbid;
    soldTickets-=maximalbid;
    payable(owner).transfer(maximalbid*(3 gwei));
    owner = maximalBidder;
    minimalbid = maximalbid;

}

function check() external view returns(bool,bool){
    return( (soldTickets*(3 gwei) <= this.getBalance()),
    (soldTickets*(3 gwei) >= this.getBalance()));
}

}