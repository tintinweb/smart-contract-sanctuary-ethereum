/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

contract SimpleAuction{
    uint public highestBid;
    address public highestBidder;
    bool ended;
    uint public endTime;
    mapping(address=>uint) pendingReturns;
    address payable beneficiary;

    event HighestBidIncreased(address Bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    error AuctionHasAlreadyEnded();
    error BidIsNotHigher(uint highestBid);
    error AuctionEndAlreadyCalled();

    constructor(address payable addressBeneficiary, uint bidTime){
        beneficiary = addressBeneficiary;
        endTime = block.timestamp + bidTime;
    }
    function bid() external payable{
        if(block.timestamp > endTime){
            revert AuctionHasAlreadyEnded();
        } 
        if(msg.value <= highestBid){
            revert BidIsNotHigher(highestBid);
        }
        if(highestBid != 0){
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function auctionEnd() external{
        if(block.timestamp > endTime){
            revert AuctionHasAlreadyEnded();
        }
        if(ended){
            revert AuctionEndAlreadyCalled();
        }
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }

    function withdraw() external returns(bool){
        uint amount = pendingReturns[msg.sender];
        if(amount > 0){
            pendingReturns[msg.sender] = 0;

            if(!payable(msg.sender).send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
}