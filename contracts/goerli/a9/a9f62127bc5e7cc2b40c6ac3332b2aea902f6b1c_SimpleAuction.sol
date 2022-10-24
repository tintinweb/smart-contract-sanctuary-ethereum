/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

pragma solidity >=0.4.22 <0.6.0;

contract SimpleAuction {
  address payable public beneficiary;
  uint public auctionEndTime;
  uint minimumBid;
  uint bidIncrement;

  address public highestBidder;
  uint public highestBid;
  mapping(address => uint) pendingReturns;
  bool ended;
  bool received;

  event HighestBidIncreased(address bidder, uint amount);
  event AuctionEnded(address winner, uint amount);

  constructor(
    uint _biddingTime,
    address payable _beneficiary,
    uint _minimumBid,
    uint _bidIncrement
  ) public {
    beneficiary = _beneficiary;
    auctionEndTime = now + (_biddingTime * 1 seconds);
    minimumBid = _minimumBid;
    bidIncrement = _bidIncrement;
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
      msg.value >= minimumBid,
      "Bid is below minimum bid."
    );
    require(
      msg.value >= highestBid + bidIncrement,
      "Increase in bid value is below bid increment."
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

  function confirmReceived() public {
    require(!received, "confirmReceived has already been called.");
    require(ended, "Auction not yet ended.");
    require(msg.sender == highestBidder, "Only the highest bidder can confirm receipt.");
    received = true;
    beneficiary.transfer(highestBid);
  }
}