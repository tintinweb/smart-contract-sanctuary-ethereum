// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Counters.sol";
import "IERC721.sol";
import "Ownable.sol";

import "console.sol";

contract NFTMarketplace is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0 ether;
    uint256 mintingPrice = 0.25 ether;
    uint256 royaltyFee = 5;
    IERC721 public parentNFT;


    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
      uint256 tokenId;
      address payable seller;
      address payable owner;
      uint256 price;
      bool sold;
      bool flag;
    }

    event MarketItemCreated (
      uint256 indexed tokenId,
      address seller,
      address owner,
      uint256 price,
      bool sold,
      bool flag
    );

    constructor() {
        parentNFT = IERC721(0xF78caeb5365a62B04D5750f1D6B542fBD27bA3C8);
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint _listingPrice) public onlyOwner {
      listingPrice = _listingPrice;
    }

    function updateRoyaltyFee(uint _royaltyFee) public onlyOwner {
      royaltyFee = _royaltyFee;
    }

    function getListingPrice() public view returns (uint256) {
      return listingPrice;
    }

    function getRoyaltyFee() public view returns (uint256) {
      return royaltyFee;
    }

    function checkIfExistsOnMarket(uint256 tokenId) public view returns (bool) {
        return idToMarketItem[tokenId].flag;
    }

    function createMarketListing(uint256 price, uint256 tokenId) public payable {
      require(msg.value == listingPrice, "Price must be equal to listing price");
      require(parentNFT.ownerOf(tokenId) == payable(msg.sender), "Only item owner can perform this operation");

      parentNFT.setApprovalForAll(address(this), true);

      if(idToMarketItem[tokenId].flag) {
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        
        parentNFT.transferFrom(msg.sender, address(this), tokenId);
      } else {
        createMarketItem(tokenId, price);
      }
    }

    /* Remove from Market */
    function removeFromMarket(uint256 tokenId) public {
      require(idToMarketItem[tokenId].seller == msg.sender, "Only item owner can perform this operation");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].seller = payable(address(0));
      parentNFT.setApprovalForAll(address(this), true);
      parentNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function createMarketItem(
      uint256 tokenId,
      uint256 price
    ) private {
      require(price > 0, "Price must be at least 1 wei");
      require(msg.value == listingPrice, "Price must be equal to listing price");

      idToMarketItem[tokenId] =  MarketItem(
        tokenId,
        payable(msg.sender),
        payable(address(this)),
        price,
        false,
        true
      );

      parentNFT.setApprovalForAll(address(this), true);
      parentNFT.transferFrom(msg.sender, address(this), tokenId);
      emit MarketItemCreated(
        tokenId,
        msg.sender,
        address(this),
        price,
        false,
        true
      );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(
      uint256 tokenId
      ) public payable {
      uint price = idToMarketItem[tokenId].price;
      address seller = idToMarketItem[tokenId].seller;
      require(msg.value == price, "Please submit the asking price in order to complete the purchase");
      idToMarketItem[tokenId].owner = payable(msg.sender);
      idToMarketItem[tokenId].sold = true;
      idToMarketItem[tokenId].seller = payable(address(0));
      _itemsSold.increment();
      parentNFT.setApprovalForAll(address(this), true);
      parentNFT.transferFrom(address(this), msg.sender, tokenId);
      payable(owner()).transfer(listingPrice);
      /** Calculate royalty fee **/
      uint priceToPaySeller = price - ((price * royaltyFee) / 100);
      payable(seller).transfer(priceToPaySeller);
    }


    /* Returns all unsold market items */
    function fetchNFTListedOnMarketplace() public view returns (MarketItem[] memory) {
      uint itemCount = _tokenIds.current();
      uint currentIndex = 0;
      uint unsoldItemCount = 0;

      for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          unsoldItemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](unsoldItemCount);
      for (uint i = 0; i < itemCount; i++) {
        if (idToMarketItem[i + 1].owner == address(this)) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    /* Returns NFTs listed on marketplace */
    function fetchNFTListedOnMarketplaceByAddress(address wallet) public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;
      uint currentIndex = 0;

      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == wallet) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      for (uint i = 0; i < totalItemCount; i++) {
        if (idToMarketItem[i + 1].seller == wallet) {
          uint currentId = i + 1;
          MarketItem storage currentItem = idToMarketItem[currentId];
          items[currentIndex] = currentItem;
          currentIndex += 1;
        }
      }
      return items;
    }

    function withdrawAll() public onlyOwner{
      payable(owner()).transfer(address(this).balance);
    }
}