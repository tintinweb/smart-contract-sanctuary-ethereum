/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;
    
    uint public minimumBid;     		// New Code
    uint public minimumBidIncrement;     	// New Code
    bool receivedGoods;		// New Code

    mapping(address => uint) pendingReturns;
    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        uint _minimumBid,  		// New Code
        uint _minimumBidIncrement 	// New Code
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = now + (_biddingTime * 1 seconds);
        minimumBid = _minimumBid;				// New Code
        minimumBidIncrement = _minimumBidIncrement;		// New Code
        receivedGoods = false;				// New Code

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

        require(  			// New Code
            msg.value > minimumBid,
            "Bid is too low."
        );

        require(  			// New Code
            msg.value > highestBid + minimumBidIncrement,
            "Bid increment is too low."
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





    function auctionEnd() public {		// Modified function
        require(now >= auctionEndTime, "Auction not yet ended.");
        if (ended) {
            emit AuctionEnded(highestBidder, highestBid);
        }

        ended = true;

        if (receivedGoods) {
            beneficiary.transfer(highestBid);
        }

    }


    function updateReceivedGoods() public {	// New Function
        require(ended, "Auction has not ended.");
        require(msg.sender == highestBidder, "You are not the highest bidder.");

        require(!receivedGoods, "Highest bidder has already received goods.");	

        receivedGoods = true;
    }
}