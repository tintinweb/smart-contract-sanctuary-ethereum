/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

pragma solidity >=0.4.22 <0.6.0;


contract SimpleAuction {
    address payable public beneficiary; 
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    uint public minimumBid;
    uint public minimumIncrement;

    mapping(address => uint) pendingReturns; 
    bool ended;
    bool goodsConfirmed;

    event HighestBidIncreased(address bidder, uint amount); 
    event AuctionEnded(address winner, uint amount);


    constructor(
        uint _biddingTime, 
        address payable _beneficiary, 
        uint _minimumBid, 
        uint _minimumIncrement
        ) 
        public {
            beneficiary = _beneficiary;
            auctionEndTime = now + (_biddingTime * 1 seconds);
            minimumBid = _minimumBid * 1000000000000000000;
            minimumIncrement = _minimumIncrement * 1000000000000000000;
        }

    function bid() public payable { 
        require(now <= auctionEndTime, "Auction already ended.");
        require(msg.value >= minimumBid, "There is a minimum bid.");

        if (highestBid != 0) {
            require(msg.value >= (highestBid + minimumIncrement), "Minimum increment.");
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
                pendingReturns[msg.sender] = amount; return false;
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

    function confirmGoods() public {
        require(msg.sender == highestBidder, "Only highest bidder can confirm goods.");
        require(ended, "Auction must have ended.");
        goodsConfirmed = true;
    }

    function payoutBeneficiary() public {
        require(goodsConfirmed, "Highest bidder must confirm goods received.");
        beneficiary.transfer(highestBid);
    }
}