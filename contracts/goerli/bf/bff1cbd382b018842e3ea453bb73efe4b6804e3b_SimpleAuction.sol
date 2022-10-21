/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;
    uint public minimumBid;
    mapping(address => uint) pendingReturns;
    bool ended;
    bool itemRecieved;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + (_biddingTime * 1 seconds);
    }

    function bid() public payable {
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        require(
            msg.value > minimumBid,
            "Your bid is less than minimum bid."
        );

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        if (itemRecieved) {
            beneficiary.transfer(highestBid);
        }
    }

    function confirmItemRecieved() public {
        require(msg.sender == highestBidder, "You are not the highest bidder.");

        itemRecieved = true;
    }
}