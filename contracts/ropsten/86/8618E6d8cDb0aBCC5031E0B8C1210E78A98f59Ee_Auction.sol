// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Auction {
    event Start();
    event End(address highestBidder, uint highestBid);
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);


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

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function bid() external payable{
        require(started, "Not started");
        require(block.timestamp < endAt, "Ended");
        require(msg.value > highestBid);

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(highestBidder, highestBid);
    }

    function end() external isSeller() {
        require(started, "Auction must be started first!");
        require(block.timestamp >= endAt, "aUCTION IS still ongoing!");
        require(!ended, "Auction is over!");

        ended = true;
        emit End(highestBidder, highestBid);
    }

    function withdrawOwner(address payable Address) external payable isSeller() {
        require(ended == true);
        require(msg.value <= getBalance());
        Address.transfer(msg.value);
    }

    function withdrawBidder() external payable {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        (bool sent, bytes memory data) = payable(msg.sender).call{value: bal}("");
        require(sent, "could not withdraw");

        emit Withdraw(msg.sender, bal);
    }
}