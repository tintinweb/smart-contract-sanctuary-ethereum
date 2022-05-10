// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Auction {
    event Start();
    event End(address highestBidder, uint highestBid);


    address payable public seller;

    bool public started;
    bool public ended;
    uint public endAt;

    uint public highestBid;
    address public highestBidder;
    mapping(address => uint) public bids;
    
    constructor () {
        seller = payable(msg.sender);
    }

    modifier isSeller() {
        require(seller == msg.sender);
        _;
    }

    modifier auctionNotStarted() {
        require(!started, 'Auction already started');
        _;
    }

    function start(uint startingBid) external isSeller() auctionNotStarted {
        started = true;
        endAt = block.timestamp + 2 days;
        highestBid = startingBid;
        emit Start();
    }

    function end() external isSeller() {
        require(started, "Auction must be started first!");
        require(block.timestamp >= endAt, "aUCTION IS still ongoing!");
        require(!ended, "Auction is over!");

        ended = true;
        emit End(highestBidder, highestBid);
    }
}