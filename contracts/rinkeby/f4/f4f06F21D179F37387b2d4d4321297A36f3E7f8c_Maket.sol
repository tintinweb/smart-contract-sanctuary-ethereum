// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";


contract Maket is ReentrancyGuard{


    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
     address public owner;
     
     constructor() {
         owner = msg.sender;
     }
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller; 
         address payable owner; 
         uint256 price;
         uint8 sold;//0取消 1挂售 2完成
     }
     
     mapping(uint256 => MarketItem) public idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        uint8 sold
     );
     
    event MarketItemSold (
        uint indexed itemId,
        address owner
    );

    
    event CancelItemItem (
        uint indexed itemId
    );
   
   
    //挂售 需要先掉NFT授权给该合约地址
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public nonReentrant {
            require(price > 0, "Price must be greater than 0");
            
            _itemIds.increment();
            uint256 itemId = _itemIds.current();
  
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                1
            );

            // IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
          
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(0),
                price,
                1
            );
        }
        
  
    //创建挂售
    function createMarketSale(
        uint256 itemId
        ) public payable nonReentrant {
            address nftContract = idToMarketItem[itemId].nftContract;
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            uint8 sold = idToMarketItem[itemId].sold;
            address payable seller = idToMarketItem[itemId].seller;
            require(msg.value >= price, "Please submit an asking price to complete your purchase");
            require(sold == 1, "This sale has ended");

            emit MarketItemSold(
                itemId,
                msg.sender
                );

            payable(seller).transfer(price);
           
            // ERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

            ERC721(nftContract).transferFrom(seller, msg.sender, tokenId);

            
            idToMarketItem[itemId].owner = payable(msg.sender);

            
            _itemsSold.increment();

           
            idToMarketItem[itemId].sold = 2;
        }


    //取消挂售
    function cancelMarketItem(
        uint256 itemId
        ) public nonReentrant {
            MarketItem storage item = idToMarketItem[itemId];
            require(msg.sender == item.seller, "You do not have the right to cancel");
            require(1 == item.sold, "Order completed or cancelled");
            item.sold = 0;

            emit CancelItemItem(itemId);
        }
        
   
    //获取市场项目
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }


        //查询我的交易
        function fetchMyNFTs() public view returns (MarketItem[] memory){
            //get total number of items ever created
            uint totalItemCount = _itemIds.current();

            uint itemCount = 0;
            uint currentIndex = 0;


            for(uint i = 0; i < totalItemCount; i++){
                //get only the items that this user has bought/is the owner
                if(idToMarketItem[i+1].owner == msg.sender){
                    itemCount += 1; //total length
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint i = 0; i < totalItemCount; i++){
               if(idToMarketItem[i+1].owner == msg.sender){
                   uint currentId = idToMarketItem[i+1].itemId;
                   MarketItem storage currentItem = idToMarketItem[currentId];
                   items[currentIndex] = currentItem;
                   currentIndex += 1;
               }
            }
            return items;

        }
}