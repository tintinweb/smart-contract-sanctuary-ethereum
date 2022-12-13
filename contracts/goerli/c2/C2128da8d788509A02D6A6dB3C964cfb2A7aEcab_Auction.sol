// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Auction{
    address payable public beneficiary;
    uint public auctionEndTime;

    address public HighestBidder;
    uint public HighestBid;

    error BidNotHighEnough(uint HighestBid);
    error AuctionNotYetEnded();
    error AuctionAlreadyEnded();
    error AuctionEndAlreadyCalled();
    
    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address sender, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(address _beneficiary, uint biddingTime){
        beneficiary = payable(_beneficiary);
        auctionEndTime = block.timestamp + biddingTime;
    }
    
    function bid() payable external {
        if (block.timestamp > auctionEndTime){
            revert AuctionAlreadyEnded();
        }
        if (msg.value <= HighestBid){
            revert BidNotHighEnough(HighestBid);
        }
        if (HighestBid != 0){
            pendingReturns[HighestBidder] += HighestBid;
        }
        HighestBidder = msg.sender;
        HighestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns(bool){
        uint amount = pendingReturns[msg.sender];
        if (amount > 0){
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() external {
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();

        // 2. Effects
        ended = true;
        emit AuctionEnded(HighestBidder, HighestBid);

        // 3. Interaction
        beneficiary.transfer(HighestBid);
    }
}