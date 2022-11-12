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
  event Transfer();
  event Sale(address sender, uint amount);

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

  function transfer(uint _nftId, uint _price) external {
    require(msg.sender == seller, "not seller");
    price = _price;
    nft.transferFrom(seller, address(this), _nftId);
  }

  function sale(uint _nftId) external payable {
    require(msg.value >= price, "value < price");
    price = msg.value;
    buyer = msg.sender;
    nftId = _nftId;
    emit Sale(msg.sender, msg.value);
    if (buyer != address(0)) {
      nft.transferFrom(address(this), buyer, nftId);
      (bool success, ) = seller.call{value: price}(""); 
      require(success, "call failed");  
    } else {
      nft.transferFrom(address(this), seller, nftId);
    }
  }

}