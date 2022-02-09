/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

/*
 * ANFT : Auctionable NFT
 */
contract ANFT {
    struct Bidder {
        address addr;
        uint bid;
    }

    address public author = msg.sender;
    address private owner = author;
    mapping( address => uint ) private ticketBalance;
    string public constant URL="https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    uint public soldTickets = 0;
    bool private roundOpen = false;
    Bidder[] private bidders;
    uint private minimalPrice = 10;
    bool private canIncMinPrice = true;

    function buyTicket (uint nbTicket) external payable {
        require(nbTicket <= 100 && msg.value == nbTicket * (3 gwei));
        ticketBalance[msg.sender] += nbTicket;
        soldTickets += nbTicket;
    }

    function sellTicket (uint nbTicket) external payable {
        require(nbTicket <= ticketBalance[msg.sender]);
        ticketBalance[msg.sender] -= nbTicket;
        soldTickets -= nbTicket;
        (bool success,) = msg.sender.call{value: nbTicket * (3 gwei)}("");
        require(success);
    }

    function getTicketBalance () external view returns(uint) {
        return ticketBalance[msg.sender];
    }

    function getOwner () external view returns(address) {
        return owner;
    }

    function giveForFree (address newOwner) external {
        require(msg.sender == owner && newOwner != owner);
        owner = newOwner;
        canIncMinPrice = true;
    }

    function getBalance () external view returns(uint) {
        return address(this).balance;
    }

    function newBid (uint nbTicket) external {
        require(nbTicket <= ticketBalance[msg.sender]);
        if(!roundOpen) {
            roundOpen = true;
        }
        if(!isBidder(msg.sender)){
            Bidder memory bidder = Bidder(msg.sender,nbTicket);
            bidders.push(bidder);
            ticketBalance[msg.sender] -= nbTicket;
        }else{
            modifyBid(msg.sender, nbTicket);
        }
    }

    function isBidder (address a) private view returns(bool) {
        uint length = bidders.length;
        for (uint i=0;i<length;i++){
            if (bidders[i].addr == a) return true;
        }
        return false;
    }

    function modifyBid (address bidder, uint ticketToAdd) private {
        uint length = bidders.length;
        for (uint i=0; i<length; i++){
            if (bidders[i].addr == bidder) {
                bidders[i].bid += ticketToAdd;
                ticketBalance[bidder] -= ticketToAdd;
                return;
            }
        }
    }

    function getMaximalBid () external view returns(uint) {
        uint length = bidders.length;
        uint maxBid = 0;
        for (uint i=0; i < length; i++) {
            if (bidders[i].bid > maxBid) {
                maxBid = bidders[i].bid;
            }
        }
        return maxBid;
    }

    function getMaximalBidder () external view returns(address) {
        uint length = bidders.length;
        Bidder memory maxBidder = Bidder(address(0),0);
        for (uint i=0; i < length; i++) {
            if (bidders[i].bid > maxBidder.bid) {
                maxBidder.bid = bidders[i].bid;
                maxBidder.addr = bidders[i].addr;
            }
        }
        return maxBidder.addr;
    }

    function getMinimalPrice () external view returns(uint) {
        return minimalPrice;
    }

    function increaseMinimalPrice () external {
        require(msg.sender == owner && canIncMinPrice);
        minimalPrice += 10;
        canIncMinPrice = false;
    }

    function closeAuction () external {
        require(roundOpen);
        uint length = bidders.length;
        Bidder memory maxBidder = Bidder(address(0),0);
        for (uint i=0; i < length; i++) {
            if (bidders[i].bid > maxBidder.bid) {
                maxBidder.bid = bidders[i].bid;
                maxBidder.addr = bidders[i].addr;
            }
        }
        if(maxBidder.bid < minimalPrice) {
            revert();
        }
        ticketBalance[owner] += maxBidder.bid;
        minimalPrice = maxBidder.bid;
        owner = maxBidder.addr;
        canIncMinPrice = true;
        for (uint i=0; i < length; i++) {
            if (bidders[i].addr != maxBidder.addr){
                ticketBalance[bidders[i].addr] += bidders[i].bid;
            }
        }
        delete bidders;
        roundOpen = false;
    }

    function check () external view returns(bool,bool) {
        return ( (soldTickets * (3 gwei) <= this.getBalance()), (soldTickets * (3 gwei) >= this.getBalance()) );
    }
}