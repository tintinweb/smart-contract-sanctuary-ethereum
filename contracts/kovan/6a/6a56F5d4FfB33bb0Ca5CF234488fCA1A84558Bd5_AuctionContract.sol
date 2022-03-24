/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

contract AuctionContract{

    uint public soldTickets;
    string public url;
    address public author;

    mapping (address => uint) ticket_Registry;
    mapping (address => uint) auction_Registry;
    mapping (address => bool) owner_Registry;

    uint num_bidders;
    uint minimalPrice;
    bool auctionIsOpen;
    address[] bidders;
    address owner;
    

    constructor() {
        author = msg.sender;
        owner = msg.sender;
        url = 'achrafjenzri.com';
        auctionIsOpen = true;
        soldTickets = 0;
        num_bidders = 0;
        minimalPrice = 10;
        owner_Registry[owner] = false;
    }


    function buy(uint nbTickets) external payable {
        require(msg.value == nbTickets * (3 gwei));
        ticket_Registry[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint nbTickets) external {
        require(ticket_Registry[msg.sender] >= nbTickets);
        ticket_Registry[msg.sender] -= nbTickets;
        payable(msg.sender).transfer(nbTickets * (3 gwei));
    }

    function newBid(uint nbTickets) external {
        require(ticket_Registry[msg.sender] >= nbTickets);
        auction_Registry[msg.sender] += nbTickets;
        ticket_Registry[msg.sender] -= nbTickets;

        if (!is_bidder(msg.sender)) {
            bidders.push(msg.sender);
            num_bidders++;
        }
        auctionIsOpen = true;
    }

    function is_bidder(address ad) private view returns(bool){
        for (uint i = 0; i < num_bidders; i++)
            if (bidders[i] == ad) return true;
        return false;
    }

    function giveForFree(address new_owner) external {
        require(msg.sender == owner);
        owner = new_owner;
        if (!owner_Registry[owner])
            owner_Registry[owner] = false;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getMaximalBid() external view returns(uint) {
        uint maximum_bid = 0;
        for (uint i = 0; i < num_bidders; i++)
            if (auction_Registry[bidders[i]] > maximum_bid)
                maximum_bid = auction_Registry[bidders[i]];
        return maximum_bid;
    }

    function getMaximalBidder() external view returns(address) {
        uint maximum_bid = this.getMaximalBid();
        address maximum_bidder;
        for (uint i = 0; i < num_bidders; i++)
            if (auction_Registry[bidders[i]] == maximum_bid)
                maximum_bidder = bidders[i];
        return maximum_bidder;
    }

    function getMinimalPrice() external view returns(uint) {
        return minimalPrice;
    }

    function increaseMinimalPrice() external {
        require(msg.sender == owner);
        require(!owner_Registry[owner]);
        minimalPrice += 10;
        owner_Registry[owner] = true;
    }

    function returnBids() private {
        for (uint i = 0; i < num_bidders; i++) {
            ticket_Registry[bidders[i]] += auction_Registry[bidders[i]];
            auction_Registry[bidders[i]] = 0;
        }
        num_bidders = 0;
    }

    function closeAuction() external {
        require(auctionIsOpen);
        require(this.getMaximalBid() >= minimalPrice);

        auctionIsOpen = false;
        uint maximum_bid = this.getMaximalBid();
        address maximum_bidder = this.getMaximalBidder();

        ticket_Registry[owner] += maximum_bid;
        auction_Registry[maximum_bidder] = 0;
        owner = maximum_bidder;
        if (!owner_Registry[owner])
            owner_Registry[owner] = false;
        minimalPrice = maximum_bid;
        returnBids();
    }

    function check() external view returns(bool, bool){
        return( (soldTickets * (3 gwei) <= this.getBalance()),
                (soldTickets * (3 gwei) >= this.getBalance()) );
    }

}