/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
pragma abicoder v2;

contract MyAuction{
    string public url;
    address public author;
    uint private soldTickets;

    // minimum number of tickets to win
    uint private minPrice;

    bool private auction_open = false;

    address private owner;

    // nb of tickets per participant
    mapping (address => uint) private tickets_array;

    // proposed price in tickets
    mapping (address => uint) private tickets_bid_array;

    // array of bidders
    address[] private bidder_array;

    mapping (address => uint) private owner_has_increased;

    uint private maxBid;
    address private maxBidder;

    constructor(string memory nft) {
        owner = msg.sender;
        url = nft;
        minPrice = 10;
        author = msg.sender;
        maxBid = 0;
    }

    function buy(uint nbTickets) external payable {
        require(msg.value==nbTickets * (3 gwei));
        tickets_array[msg.sender] += nbTickets;
        soldTickets += nbTickets;
    }

    function sell(uint nbTickets) external {
        require(tickets_array[msg.sender] >= nbTickets + tickets_bid_array[msg.sender]);
        tickets_array[msg.sender] -= nbTickets;
        soldTickets -= nbTickets;
        payable(msg.sender).transfer(nbTickets * (3 gwei));
    }

    function getOwner() view external returns(address) {
        return owner;
    }

    function giveForFree(address a) external {
        require(owner==msg.sender && a != address(0));
        if (auction_open) {
            auction_open = false;
            for (uint i = 0; i < bidder_array.length; i++) {
                tickets_bid_array[bidder_array[i]] = 0;
            }
            delete bidder_array;
            maxBidder = address(0);
            maxBid = 0;
        }
        owner = a;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    // cumulative
    function newBid(uint nbTickets) external {
        require(nbTickets > 0 && tickets_array[msg.sender] >= nbTickets + tickets_bid_array[msg.sender]);
        auction_open = true;
        tickets_bid_array[msg.sender] += nbTickets;
        if (maxBid < tickets_bid_array[msg.sender]) {
            maxBid = tickets_bid_array[msg.sender];
            maxBidder = msg.sender;
        }
        if (!member(msg.sender, bidder_array)) {
            bidder_array.push(msg.sender);
        }
    }

    function getMaximalBid() external view returns(uint) {
        require(auction_open);
        return maxBid;
    }

    function getMaximalBidder() external view returns(address) {
        require(auction_open);
        return maxBidder;
    }

    function getMinimalPrice() view external returns(uint) {
        return minPrice;
    }

    function increaseMinimalPrice() external {
        require(msg.sender == owner && owner_has_increased[msg.sender] == 0);
        owner_has_increased[msg.sender] = 1;
        minPrice += 10;
    }

    function closeAuction() external {
        require(auction_open && maxBid >= minPrice);
        auction_open = false;
        tickets_array[maxBidder] -= maxBid;
        tickets_array[owner] += maxBid;
        owner = maxBidder;
        minPrice = maxBid;
        for (uint i = 0; i < bidder_array.length; i++) {
            tickets_bid_array[bidder_array[i]] = 0;
        }
        delete bidder_array;
        maxBidder = address(0);
        maxBid = 0;
    }

    function check() external view returns(bool,bool) {
        return( (soldTickets*(3 gwei) <= this.getBalance()),
                (soldTickets*(3 gwei) >= this.getBalance()));
    }

    function member(address s, address[] memory tab) pure private returns(bool){
        uint length= tab.length;
        for (uint i=0;i<length;i++) {
            if (tab[i] == s) return true;
        }
        return false;
    }
}