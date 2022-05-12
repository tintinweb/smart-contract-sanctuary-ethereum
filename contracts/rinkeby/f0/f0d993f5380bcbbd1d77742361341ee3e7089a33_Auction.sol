/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
contract Auction {
  address public manager;
  address public seller;
  address public latestBidder;
  uint public latestBid;

  event Bid(address indexed _from, uint _value);
  event RefundBid(address indexed _bidder, uint _value);
  event CreateAuction(address indexed _creator, uint _value);
  event CloseAuction(address indexed _auctionWinner, address indexed _seller, uint _value);

  constructor() {
    manager = msg.sender;
  }

  function startAuction(uint openingBidFinney) public {
    require(seller == address(0), "Auction already running");
    require(openingBidFinney > 0, "Opening bid must be at least 1 Finney");
    uint bidValue = openingBidFinney * 1000000000000000;
    latestBid = bidValue - 1;// .001 Eth (1 Finney) increments -1 Wei to allow for openingBidFinney to be first bid
    seller = msg.sender;
    emit CreateAuction(msg.sender, bidValue); 
  }

  function placeBid() public payable {
    require(seller != address(0), "No auction running to bid against");
    require(msg.value > latestBid, "Bid not high enough");
    if (latestBidder != address(0)) {
      payable(latestBidder).transfer(latestBid);
      emit RefundBid(latestBidder, latestBid);
    }
    latestBidder = msg.sender;
    latestBid = msg.value;
    emit Bid(msg.sender, msg.value);
  }

  function finishAuction() restricted public {
    require(seller != address(0), "No auction running to finish");
    uint currentBalance = address(this).balance;
    payable(seller).transfer(currentBalance);
    emit CloseAuction(latestBidder, seller, currentBalance);
    latestBid = 0;
    latestBidder = address(0);
    seller = address(0);
  }

  //You would normally make this type of function restricted.
  //This being public is just for testing to allow anyone to become the "manager"
  function makeMeManager() public { 
    manager = msg.sender;
  }

  modifier restricted() {
    require(msg.sender == manager, "You must be the manager of this contract to call this function.");
    _;
  }
}