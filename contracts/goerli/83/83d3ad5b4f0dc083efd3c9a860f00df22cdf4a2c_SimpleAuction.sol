/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

pragma solidity >=0.4.22 <0.6.0;
contract SimpleAuction {
    /**
    @param beneficiary The person who will benefit from the bid
    @param auctionEndTime The end time for the auction
    @param highestBidder The person who made the highest bid
    @param highestBid The highest bid made
    @param pendingReturns A hashtable to keep track of how much money will be returned to the person of the address
    @param ended A boolean to determine whether auctionEnd had been called
    @param HighestBidIncreased The bidder who made a higher bid than the highest bid will be emitted
    @param AuctionEnded The winner and the amount paid by the winner will be emitted
    */
    address payable public beneficiary; 
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns; 
    bool ended;
    event HighestBidIncreased(address bidder, uint amount); 
    event AuctionEnded(address winner, uint amount);

    uint public mimimum_increment;
    uint public minimum_bid;
    bool goodsReceived;

    /**
    When an instance of the contract is initialised, we set the beneficiary 
    variable to the person in the arguments passed and we will set the 
    auctionEndTime to be the number of bidding time in seconds
    */
    constructor(uint _biddingTime, address payable _beneficiary) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + (_biddingTime * 1 seconds);
        goodsReceived = false;
    }

    /**
    When the bid function is called, the highestBidder for the previous
    round will get the highestBid made added into the pendingReturns in his
    function.

    We then change the highestBidder and highestBid to the one who called
    the function.
    */
    function bid() public payable { 
        require(now <= auctionEndTime, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");

        // Use to determine if the new amount is the minimum bid
        require(msg.value > minimum_bid, "The bid must be greater than the minimum bid.");
        require(msg.value >= highestBid + minimum_bid, "Not enough funds to place the bid");

        if (highestBid != 0) { 
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }


    /**
    Return the money made by the person.

    @return true If the transaction was successful
    @return false If the transaction was not successful
    */
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

    /**
    When the auction end is called for the first time after the auctionEndTime,
    we let everyone know who the highestBidder is and his highest bid. Then we
    transfer the beneficiary the highestBid.
    */
    function auctionEnd() public {
        require(now >= auctionEndTime, "Auction not yet ended."); 
        require(!ended, "auctionEnd has already been called.");
        require(goodsReceived);
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid); 
    }

    /**
    This allows the beneficiary to set the minimum bid.
    @param x The minimum bid amount
    */
    function setMinimumBid(uint x) public {
        require(msg.sender == beneficiary, "You must be the beneficiary to set the minimum bid.");
        minimum_bid = x;
    }

    /**
    This allows the beneficiary to set the minimum increment
    @param x The minimum increment
    */
    function setMinimumIncrement(uint x) public  {
        require(msg.sender == beneficiary, "You must be the beneficiary to set the minimum increment");
        mimimum_increment = x;
    }

    function receivedGoods() public returns (bool) {
        require(msg.sender == highestBidder);
        require(now >= auctionEndTime);
        require(!ended);
        require(!goodsReceived);
        goodsReceived = true;
    }
}