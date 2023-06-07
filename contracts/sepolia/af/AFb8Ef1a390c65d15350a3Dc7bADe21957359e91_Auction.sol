/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

contract Auction {
    
    enum DealStatus { Active, Closed, Sold, Complete }

    struct Score {
        uint score;
        uint reviewNum;
    }

    struct Bid {
        address payable bidder;
        uint bid;
    }

    struct Deal {
        address payable seller;
        uint256 highestBid;
        address payable highestBidder;
        DealStatus status;
        string hash;
        string dscHash;
        string cid;
        uint256 endBlock;
        uint payWindow;
        Bid[] pendingBids;
    }

    mapping(uint => Deal) public deals;
    mapping(address => Score) public scores;
    uint public dealIndex;
    address payable public owner;
    uint balance;

    constructor() {
        owner = payable(msg.sender);
        dealIndex = 0;
        balance = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier dealIsActive(uint dealId) {
        require(deals[dealId].status == DealStatus.Active, "Deal is not active");
        _;
    }

    modifier dealIsClosed(uint dealId) {
        require(deals[dealId].status == DealStatus.Closed, "Deal is not closed yet");
        _;
    }

    modifier dealIsSold(uint dealId) {
        require(deals[dealId].status == DealStatus.Sold, "Deal is not sold yet");
        _;
    }

    modifier bidderIsHighest(uint dealId) {
        require(msg.sender == deals[dealId].highestBidder, "Only the highest bidder can perform this action");
        _;
    }

    function createDeal(string memory _hash, string memory _dscHash) public {
        deals[dealIndex].seller = payable(msg.sender);
        deals[dealIndex].hash = _hash;
        deals[dealIndex].dscHash = _dscHash;
        deals[dealIndex].status = DealStatus.Active;
        deals[dealIndex].endBlock = block.number + 5760; // About 24 hours in blocks
        deals[dealIndex].payWindow = 10;
        dealIndex++;
    }

    function bid(uint dealId, uint bidAmount) public payable dealIsActive(dealId) {
        require(block.number <= deals[dealId].endBlock, "Bidding time has ended");
        require(bidAmount > deals[dealId].highestBid, "There already is a higher bid");
        require(msg.value >= 0.0015 ether, "Must send at least 0.0015 ether as deposit");

        balance += msg.value;

        // Store the old highest bid in pendingBids
        if (deals[dealId].highestBid != 0) {
            deals[dealId].pendingBids.push(Bid(deals[dealId].highestBidder, deals[dealId].highestBid));
        }

        // Set the new highest bid
        deals[dealId].highestBid = bidAmount;
        deals[dealId].highestBidder = payable(msg.sender);
    }

    function closeBidding(uint dealId) public dealIsActive(dealId) {
        require(block.number > deals[dealId].endBlock, "Bidding time has not ended yet");
        deals[dealId].status = DealStatus.Closed;
    }

    function confirmPayment(uint dealId) public payable dealIsClosed(dealId) bidderIsHighest(dealId) {
        require(msg.value >= deals[dealId].highestBid, "Must pay the full bid amount");
        deals[dealId].status = DealStatus.Sold;
    }

    function submitCID(uint dealId, string memory cid) public dealIsSold(dealId) {
        require(msg.sender == deals[dealId].seller, "Only the seller can submit the CID");

        deals[dealId].cid = cid;
        deals[dealId].status = DealStatus.Complete;
        deals[dealId].seller.transfer(deals[dealId].highestBid);
    }

    function defaultOnPayment(uint dealId) public dealIsClosed(dealId) bidderIsHighest(dealId) {
        require(block.number > deals[dealId].endBlock + deals[dealId].payWindow, "Pay Window still open");
        deals[dealId].payWindow += 10;
        Bid memory newBestBid = deals[dealId].pendingBids[deals[dealId].pendingBids.length-1];

        deals[dealId].highestBid = newBestBid.bid;
        deals[dealId].highestBidder = newBestBid.bidder;
        deals[dealId].pendingBids.pop();
    }

    function addReview(address _addr, uint _score) public payable {
        require(msg.value >= 0.0015 ether, "Must send at least 0.0015 ether as deposit");
        balance += msg.value;

        if(scores[_addr].reviewNum == 0)
            scores[_addr] = Score(0, 0);
        Score memory user = scores[_addr];
        user.score = (user.score * user.reviewNum + _score) / (user.reviewNum+1);
        user.reviewNum++;
        scores[_addr] = user;
    }

    function collectFunds() public onlyOwner {
        require(balance > 0, "No funds to collect");
        owner.transfer(balance);
        balance = 0;
    }
}