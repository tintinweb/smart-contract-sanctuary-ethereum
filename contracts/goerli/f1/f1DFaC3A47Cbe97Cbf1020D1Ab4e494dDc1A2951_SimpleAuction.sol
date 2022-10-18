/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;
    uint public minBid;
    uint public incrBid;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);


    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        uint _minBid,
        uint _incrBid
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + (_biddingTime * 1 seconds);
        minBid = _minBid;
        incrBid = _incrBid;
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
            msg.value >= minBid,
            "Bid does not meet minimum bid."
        );
        
        require(
            msg.value >= highestBid + incrBid,
            "Bid does not meet requirements."
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

    function confirmGoods() public {
        require(ended);
        require(msg.sender == highestBidder);
        
        beneficiary.transfer(highestBid);
    }


    function auctionEnd() public {
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

    }
}