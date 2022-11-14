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
  event Sale(address buyer, uint amount);

  IMyNFT public immutable nft;
  uint public nftId;
  address payable public seller;
  uint public ask;
  address public buyer;

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

  function sale(uint _nftId) external payable {
    buyer = msg.sender;
    require(msg.value >= ask, "value < ask");
    nftId = _nftId;
    nft.transferFrom(address(this), buyer, nftId);
    (bool success, ) = seller.call{value: ask}(""); 
    require(success, "call failed");  
    emit Sale(buyer, ask);
  }

}