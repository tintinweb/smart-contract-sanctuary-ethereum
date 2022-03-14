// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

contract NFTMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

    address payable owner;
    uint256 serviceCharge = 3;
    uint256 listingPrice = 0.003 ether;

  constructor(
        address ownerAddress
      ) {
    owner = payable(ownerAddress);
              
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner;
    uint256 price;
    uint256 royaltyfee;
    address nftCreator;
  }

  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    uint256 royaltyfee,
    address nftCreator
  );

  function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }


  function getMarketItem(uint256 marketItemId) public view returns (MarketItem memory) {
    return idToMarketItem[marketItemId];
  }


  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 royaltyfee,
    address nftCreator
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
  
    idToMarketItem[itemId] =  MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      royaltyfee,
      nftCreator
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    payable(owner).transfer(msg.value);

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      royaltyfee,
      nftCreator
    );
  }

  function createMarketSale(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;
    require(msg.value == price, "Please submit the asking price in order to complete the purchase");
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    _itemsSold.increment();
    uint saleFee = (msg.value * serviceCharge) / 100;
    uint256 royaltyCashBack = (idToMarketItem[itemId].royaltyfee * msg.value ) / 100;
    payable(owner).transfer(saleFee);
    address theCreator = idToMarketItem[itemId].nftCreator; 
    address payable theSeller = idToMarketItem[itemId].seller;

    if(theSeller != theCreator){
    uint256 remainingFunds = msg.value - royaltyCashBack - saleFee;
    payable(theSeller).transfer(remainingFunds);
        payable(theCreator).transfer(royaltyCashBack);

    }
    else{
        uint256 remainingFunds = msg.value - saleFee;
        payable(theSeller).transfer(remainingFunds);
    }
  }

  function fetchMarketItem(uint itemId) public view returns (MarketItem memory) {
    MarketItem memory item = idToMarketItem[itemId];
    return item;
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 0; i < itemCount; i++) {
      if (idToMarketItem[i + 1].owner == address(0)) {
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == msg.sender) {
        uint currentId = idToMarketItem[i + 1].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
   
    return items;
  }

  function changeListingPrice(uint256 newListingFee ) public payable{
            require(msg.sender == owner, "Not Authorized to Change Listing Fee");
            listingPrice = newListingFee;
    }
    function changeSaleFee(uint256 newSaleFee) public payable{
        
        require(msg.sender == owner,  "Not Authorized to Change Sale Fee");
        serviceCharge =  newSaleFee;
    }        
    
    function changeListingFeeCollector(address payable newListingFeeCollector) public payable{
        require(msg.sender == owner, "Not Authorized to Change Listing Feee Collector");
        owner = newListingFeeCollector;
    }
    
    function getServiceCharge() public view returns(uint256){
        return serviceCharge;
    }

}