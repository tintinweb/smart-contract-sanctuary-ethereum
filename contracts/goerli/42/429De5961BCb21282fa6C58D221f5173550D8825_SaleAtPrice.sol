// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMyNFT {
  function transferFrom (
    address from,
    address to,
    uint nftId
  ) external;
}

contract SaleAtPrice {
  event Transfer(uint amount);
  event Bid(address sender, uint amount);
  event Sale(address buyer, uint amount);

  IMyNFT public immutable nft;
  uint public nftId;
  address payable public seller;
  uint public ask;
  address public buyer;
  uint public bid;

  constructor(
    address _nft
  ) {
    nft = IMyNFT(_nft);
    seller = payable(msg.sender);
  }

  function transfer(uint _nftId, uint amount) external {
    require(msg.sender == seller, "not seller");
    ask = amount;
    nft.transferFrom(seller, address(this), _nftId);
    emit Transfer(ask);
  }

  function theBid() external payable {
    require(msg.value >= bid, "value < bid");
    bid = msg.value;
    buyer = msg.sender;
    emit Bid(msg.sender, msg.value);
  }

  function sale(uint _nftId) external payable {
    nftId = _nftId;
    nft.transferFrom(address(this), buyer, nftId);
    (bool success, ) = seller.call{value: bid}(""); 
    require(success, "call failed");  
    emit Sale(buyer, bid);
  }

}