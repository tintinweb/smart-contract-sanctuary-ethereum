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
  address public buyer;
  uint public price;


  constructor(
    address _nft
  ) {
    nft = IMyNFT(_nft);
    seller = payable(msg.sender);
  }

  function transfer(uint _nftId, uint amount) external {
    require(msg.sender == seller, "not seller");
    price = amount;
    nftId = _nftId;
    nft.transferFrom(seller, address(this), nftId);
    emit Transfer(price);
  }

  function sale() external payable {
    buyer = msg.sender;
    require(msg.value >= price, "value < price");
    nft.transferFrom(address(this), buyer, nftId);
    (bool success, ) = seller.call{value: msg.value}(""); 
    require(success, "call failed");  
    emit Sale(buyer, price);
  }

}