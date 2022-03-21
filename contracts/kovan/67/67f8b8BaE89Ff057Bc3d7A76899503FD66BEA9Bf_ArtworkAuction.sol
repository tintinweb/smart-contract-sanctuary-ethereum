/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

contract ArtworkAuction{

    uint public soldTickets;
    string public url;
    address public author;

    bool auctionIsOpen;
    address[] bidders;
    uint n_bidders;
    uint minimalPrice;
    address owner;
    mapping (address => uint) ticketRegistry;
    mapping (address => uint) auctionRegistry;
    mapping (address => bool) increaseRegistry;

    constructor() {
        author = msg.sender;
        owner = msg.sender;
        url = 'SoaresCespedesMunozLaadhar.com';
        auctionIsOpen = true;
        soldTickets = 0;
        n_bidders = 0;
        minimalPrice = 10;
        increaseRegistry[owner] = false;
    }

    function sum_overflows(uint n1, uint n2) private pure returns(bool){
        return (n1 + n2 < n1 || n1 + n2 < n2);
    }

    function mult_overflows(uint n1, uint n2) private pure returns(bool){
        return (n1 * n2 < n1 || n1 * n2 < n2);
    }

    function buy(uint nbTickets) external payable {
        require(!mult_overflows(nbTickets, 3 gwei));
        require(msg.value == nbTickets * (3 gwei));
        require(!sum_overflows(ticketRegistry[msg.sender], nbTickets));
        require(!sum_overflows(soldTickets, nbTickets));
        ticketRegistry[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint nbTickets) external {
        require(ticketRegistry[msg.sender] >= nbTickets);
        ticketRegistry[msg.sender] -= nbTickets;
        payable(msg.sender).transfer(nbTickets * (3 gwei));
    }

    function newBid(uint nbTickets) external {
        require(ticketRegistry[msg.sender] >= nbTickets);
        auctionRegistry[msg.sender] += nbTickets;
        ticketRegistry[msg.sender] -= nbTickets;

        if (!is_bidder(msg.sender)){
            bidders.push(msg.sender);
            n_bidders++;
        }
        auctionIsOpen = true;
    }

    function is_bidder(address ad) private view returns(bool){
        for (uint i = 0; i < n_bidders; i++)
            if (bidders[i] == ad) return true;
        return false;
    }

    function giveForFree(address new_owner) external {
        require(msg.sender == owner);
        owner = new_owner;
        if (!increaseRegistry[owner])
            increaseRegistry[owner] = false;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getMaximalBid() external view returns(uint) {
        uint max_bid = 0;
        for (uint i = 0; i < n_bidders; i++)
            if (auctionRegistry[bidders[i]] > max_bid)
                max_bid = auctionRegistry[bidders[i]];
        return max_bid;
    }

    function getMaximalBidder() external view returns(address) {
        uint max_bid = this.getMaximalBid();
        address max_bidder;
        for (uint i = 0; i < n_bidders; i++)
            if (auctionRegistry[bidders[i]] == max_bid)
                max_bidder = bidders[i];
        return max_bidder;
    }

    function getMinimalPrice() external view returns(uint) {
        return minimalPrice;
    }

    function increaseMinimalPrice() external {
        require(msg.sender == owner);
        require(!increaseRegistry[owner]);
        require(!sum_overflows(minimalPrice, 10));
        minimalPrice += 10;
        increaseRegistry[owner] = true;
    }

    function returnBids() private {
        for (uint i = 0; i < n_bidders; i++) {
            ticketRegistry[bidders[i]] += auctionRegistry[bidders[i]];
            auctionRegistry[bidders[i]] = 0;
        }
        n_bidders = 0;
    }

    function closeAuction() external {
        require(auctionIsOpen);
        require(this.getMaximalBid() >= minimalPrice);

        auctionIsOpen = false;
        uint max_bid = this.getMaximalBid();
        address max_bidder = this.getMaximalBidder();

        ticketRegistry[owner] += max_bid;
        auctionRegistry[max_bidder] = 0;
        owner = max_bidder;
        if (!increaseRegistry[owner])
            increaseRegistry[owner] = false;
        minimalPrice = max_bid;
        returnBids();
    }

    function check() external view returns(bool, bool){
        return( (soldTickets * (3 gwei) <= this.getBalance()),
                (soldTickets * (3 gwei) >= this.getBalance()) );
    }

}