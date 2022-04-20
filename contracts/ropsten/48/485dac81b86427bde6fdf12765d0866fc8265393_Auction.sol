/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.5.0;

// bugs:
// 1. Auction can never end
// 2. highest bidder can never be refunded their highest bid

contract Auction {
    uint auctionStart;
    uint biddingTime;
    address payable beneficiary;

    bool ended = false;
    address payable highestBidder = address(0);
    uint highestBid = 0;
    mapping(address => uint) pendingReturns;

    constructor(uint _auctionStart, uint _biddingTime, address payable _beneficiary) public {
        auctionStart = _auctionStart;
        biddingTime = _biddingTime;
        beneficiary = _beneficiary;
    }

    function Bid() public payable {
        uint end = auctionStart + biddingTime;
        if(end < block.number || ended) {
            revert();
        }
        else {
            if(msg.value <= highestBid) {
                revert();
            }
            else {
                pendingReturns[highestBidder] += highestBid; 
                highestBidder = msg.sender;
                highestBid = msg.value;
            }
        }
    }

    function Withdraw() public {
        if(pendingReturns[msg.sender] != 0) {
            uint pr = pendingReturns[msg.sender];
            pendingReturns[msg.sender] = 0;
            msg.sender.transfer(pr);
        }
        else {
            revert();
        }
    }

    function AuctionEnd() public {
        uint end = auctionStart + biddingTime;

        //!ended is a bug
        if(block.number <= end || !ended) {
            revert();
        }
        else {
            ended = true;
            beneficiary.transfer(highestBid);
        }
    }
}