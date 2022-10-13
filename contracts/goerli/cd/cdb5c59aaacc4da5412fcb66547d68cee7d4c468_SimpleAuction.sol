/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {

    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    enum State { Created, Locked, Inactive }
    State public state;
    
    mapping(address => uint) pendingReturns;
    bool ended;


    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event GoodsReceived();


    /// Create a simple auction with `_biddingTime`
    /// seconds bidding time on behalf of the
    /// beneficiary address `_beneficiary`.
    constructor(
        uint _biddingTime,
        address payable _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + _biddingTime;
    }

    /// Bid on the auction with the value sent
    /// together with this transaction.
    /// The value will only be refunded if the
    /// auction is not won.
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
	        msg.value > 10,
	        "Failed to meet minimum amount required to bid."

        );

        require(
	        msg.value - highestBid > 2,
	        "Increment not high enough, please input higher amount."
        );

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
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

    modifier onlyhighestBidder() {
        require(
            msg.sender == highestBidder,
            "Only highestBidder can call this."
        );
        _;
    }

    modifier inState(State _state) {
        require(
            state == _state,
            "Invalid state."
        );
        _;
    }

    function confirmReceived()
	    public 
        onlyhighestBidder
        inState(State.Locked)
    {
        emit GoodsReceived();
        state = State.Inactive;
    }

    /// End the auction and send the highest bid
    /// to the beneficiary.
    function auctionEnd() public {
        require(now >= auctionEndTime, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");
        require(state == State.Inactive);


        ended = true;
        emit AuctionEnded(highestBidder, highestBid);


        beneficiary.transfer(highestBid);
    }
}