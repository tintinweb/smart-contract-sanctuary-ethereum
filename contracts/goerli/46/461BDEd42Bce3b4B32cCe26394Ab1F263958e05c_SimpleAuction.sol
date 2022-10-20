pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;
    uint public minBid;
    uint public minIncrement;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        uint _minBid,
        uint _minIncrement,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        minBid = _minBid;
        minIncrement = _minIncrement;
        auctionEndTime = now + (_biddingTime * 1 seconds);
    }

    function bid() public payable {
        require(
            now <= auctionEndTime,
            "Auction already ended."
        );

        require (
            msg.value > minBid,
            "Bid must be higher than the minimum bid"
        );


        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        require (
            msg.value > highestBid + minIncrement,
            "The bid increment must be higher than the minimum increment!"
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

    }

    function confirmReceive() public {
        require(highestBidder == msg.sender, "You're not the highest bidder.");
        require(ended, "Auction has not ended!");

        beneficiary.transfer(highestBid);
    }
}