// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Auction {
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;
    uint public minimumBid;
    uint public biddingTimeExtended;
    uint public commission;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        address payable _beneficiary,
        uint _biddingTime,
        uint _minimumBid,
        uint _biddingTimeExtended,
        uint _commission
    ) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
        minimumBid = _minimumBid;
        biddingTimeExtended = _biddingTimeExtended;
        commission = _commission;
    }

    function bid() public payable {
        require(block.timestamp <= auctionEndTime, "Auction already ended.");
        require(msg.value >= minimumBid, "Bid amount is below minimum.");
        require(msg.value > highestBid, "Bid amount is below highest bid.");

        // Add the previous highest bidder to the list of bidders
        if (highestBid != 0) {
            if (pendingReturns[highestBidder] == 0) {
                bidders.push(highestBidder);
            }
            pendingReturns[highestBidder] += highestBid;
        }

        // Set the new highest bidder
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // function auctionEnd() public {
    //     require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
    //     require(!ended, "Auction has already ended.");
    //     ended = true;
    //     emit AuctionEnded(highestBidder, highestBid);

    //     // Send the highest bid amount minus the commission to the beneficiary
    //     beneficiary.transfer(highestBid - commission);
    // }
    address[] private bidders;

    function auctionEnd() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "Auction has already ended.");

        // Refund all unsuccessful bidders
        for (uint i = 0; i < bidders.length; i++) {
            if (bidders[i] != highestBidder && pendingReturns[bidders[i]] > 0) {
                uint refundAmount = pendingReturns[bidders[i]];
                pendingReturns[bidders[i]] = 0;
                payable(bidders[i]).transfer(refundAmount);
            }
        }

        // Transfer the winning bid to the beneficiary minus the commission
        beneficiary.transfer(highestBid - commission);
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
    }

    function highestBidderWithdraw() private {
        require(
            msg.sender != highestBidder,
            "You cannot withdraw your bid because you are currently the highest bidder."
        );
        require(ended, "The auction has not yet ended.");
        require(
            pendingReturns[msg.sender] > 0,
            "You do not have any pending returns."
        );

        uint amount = pendingReturns[msg.sender];
        pendingReturns[msg.sender] = 0;

        if (!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
        }
    }
}