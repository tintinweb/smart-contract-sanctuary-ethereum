//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract draftLazyAuction {

  uint256 public auctionsEnded = 0;

  struct LazyAuctionVoucher {
    uint256 tokenId;
    uint256 startAuctionDate;
    uint256 endAuctionDate;
    address highestBidder;
    uint256 highestBid;
    address author;
    uint256 royaltyFee;
    bool isFirstSale;
    bytes signature;
  }

  mapping(uint256 => LazyAuctionVoucher) public AuctionEndedInfo;

  function finalize(LazyAuctionVoucher calldata lazyauctionvoucher) public returns (LazyAuctionVoucher memory){
    //TODO: Require here
    uint256 auctionId = auctionsEnded++;
    LazyAuctionVoucher memory enteredData = LazyAuctionVoucher({
      tokenId: lazyauctionvoucher.tokenId,
      startAuctionDate: lazyauctionvoucher.startAuctionDate,
      endAuctionDate: lazyauctionvoucher.endAuctionDate,
      highestBidder: lazyauctionvoucher.highestBidder,
      highestBid: lazyauctionvoucher.highestBid,
      author: lazyauctionvoucher.author,
      royaltyFee: lazyauctionvoucher.royaltyFee,
      isFirstSale: lazyauctionvoucher.isFirstSale,
      signature: lazyauctionvoucher.signature
    });
    AuctionEndedInfo[auctionId] = enteredData;
    auctionsEnded++;
    //TODO: Auction logic here
    return enteredData;
  }
}