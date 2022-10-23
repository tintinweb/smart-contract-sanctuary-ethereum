/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
    address payable public beneficiary;
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;
    uint public minReqBid;
    uint public minIncrement;

    bool public receivedGoods;

    mapping(address => uint) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        uint _biddingTime,
        address payable _beneficiary,
        uint _minReqBud,
        uint _minIncrement
    ) public {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
        minReqBid = _minReqBud;
        minIncrement = _minIncrement;
        receivedGoods = false;
    }

    function bid() public payable {
        require(
            block.timestamp <= auctionEndTime,
            "Auction already ended."
        );

        require(
            msg.value > minReqBid,
            "Bid amount too less"
        );

        require(
            msg.value > highestBid + minIncrement,
            "Increment too low"
        );

        require(
            msg.value > highestBid,
            "There already is a higher bid."
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

    function setReceivedGoods() public {
       require(block.timestamp >= auctionEndTime, "Auction not yet ended."); 
       require(msg.sender == highestBidder, "You are not the highest bidder");
       receivedGoods = true;
   }

    function auctionEnd() public {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended.");
        emit AuctionEnded(highestBidder, highestBid);

        require(
            receivedGoods == true,
            "The highest bidder hasn't received their goods"
        );

        require(!ended, "auctionEnd has already been called, and the highest bidder has received their goods");

        ended = true;

        beneficiary.transfer(highestBid);
    }
}