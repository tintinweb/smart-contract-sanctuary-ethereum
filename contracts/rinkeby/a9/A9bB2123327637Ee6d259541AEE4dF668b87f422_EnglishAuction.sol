// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address,
        address,
        uint
    ) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 immutable public nft;
    uint public nftId;

    address payable public seller;
    uint32 public endAt;
    bool public started;
    bool public ended;
    uint32 auctionTime;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;
    uint public bidderAmount ;


  error NotSeller();
  error AuctionStillRunning();  
  error NotStarted();
  error AuctionEnded();
  error BidHigher();
  error AuctionNotEnded();
  error AlreadyHighestBidder();


    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid ,  uint32 _auctionTime
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        auctionTime = _auctionTime;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }


      modifier updatesCompliance {
       if(msg.sender != seller) revert NotSeller();
       if (uint32(block.timestamp) <= endAt ) revert AuctionStillRunning();
       _;
    }

      modifier startedCompliance {
         if(!started) revert NotStarted();
         _;
      }

    
  /**
     * @dev to start the auction
     * can't start if not contract owner neither the auction has not ended
     */

    function start() external updatesCompliance() {
        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = uint32(block.timestamp) + auctionTime;

        emit Start();
    }

/**
     * @dev customers to bid
     * bid if not already higher bidder
     */

    function bid() external payable startedCompliance() {
        if (uint32(block.timestamp) > endAt) revert AuctionEnded();
        if(msg.sender== highestBidder) revert AlreadyHighestBidder();
        if(msg.value <= highestBid) revert BidHigher();

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        bidderAmount+=1 ;

        emit Bid(msg.sender, msg.value);
    }

/**
     * @dev customers can withdraw the lasts bids unless you are the highest bidder 
     */

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        bidderAmount-=1 ;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);
    }

    function end() external startedCompliance(){
        if (uint32(block.timestamp) < endAt) revert AuctionNotEnded();
        if(ended) revert AuctionEnded();

        ended = true;
        started= false;

        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }


    function tokenIdUpdate( uint _nftId ) external updatesCompliance() {
        nftId = _nftId ;
    }

    function auctionTimeUpdate( uint _auctionTime ) external updatesCompliance() {
        auctionTime = uint32(_auctionTime) ;
    }

}