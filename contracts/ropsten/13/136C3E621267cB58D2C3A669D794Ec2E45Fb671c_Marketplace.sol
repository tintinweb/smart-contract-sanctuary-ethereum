// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721.sol";
import "./NFT.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _marketItemIds;
    Counters.Counter private _tokensSold;
    Counters.Counter private _tokensCanceled;

    address payable private owner;

 
    uint256 private listingFee = 0.045 ether;

    mapping(uint256 => MarketItem) private marketItemIdToMarketItem;

    struct MarketItem {
        uint256 marketItemId;
        address nftContractAddress;
        uint256 tokenId;
        address payable creator;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool canceled;
    }

    event MarketItemCreated(
        uint256 indexed marketItemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address creator,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool canceled
    );

    constructor() {
        owner = payable(msg.sender);
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    
    function createMarketItem(
        address nftContractAddress,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant returns (uint256) {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingFee, "Price must be equal to listing price");
        _marketItemIds.increment();
        uint256 marketItemId = _marketItemIds.current();

        address creator = NFT(nftContractAddress).getTokenCreatorById(tokenId);

        marketItemIdToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            nftContractAddress,
            tokenId,
            payable(creator),
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false
        );

        IERC721(nftContractAddress).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            marketItemId,
            nftContractAddress,
            tokenId,
            payable(creator),
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false
        );

        return marketItemId;
    }

  
    function cancelMarketItem(address nftContractAddress, uint256 marketItemId) public payable nonReentrant {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(tokenId > 0, "Market item has to exist");

        require(marketItemIdToMarketItem[marketItemId].seller == msg.sender, "You are not the seller");

        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);

        marketItemIdToMarketItem[marketItemId].owner = payable(msg.sender);
        marketItemIdToMarketItem[marketItemId].canceled = true;

        _tokensCanceled.increment();
    }

   
    function getLatestMarketItemByTokenId(uint256 tokenId) public view returns (MarketItem memory, bool) {
        uint256 itemsCount = _marketItemIds.current();

        for (uint256 i = itemsCount; i > 0; i--) {
            MarketItem memory item = marketItemIdToMarketItem[i];
            if (item.tokenId != tokenId) continue;
            return (item, true);
        }

       
        MarketItem memory emptyMarketItem;
        return (emptyMarketItem, false);
    }

  
    function createMarketSale(address nftContractAddress, uint256 marketItemId) public payable nonReentrant {
        uint256 price = marketItemIdToMarketItem[marketItemId].price;
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(msg.value == price, "Please submit the asking price in order to continue");

        marketItemIdToMarketItem[marketItemId].owner = payable(msg.sender);
        marketItemIdToMarketItem[marketItemId].sold = true;

        marketItemIdToMarketItem[marketItemId].seller.transfer(msg.value);
        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);

        _tokensSold.increment();

        payable(owner).transfer(listingFee);
    }

    
    function fetchAvailableMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemsCount = _marketItemIds.current();
        uint256 soldItemsCount = _tokensSold.current();
        uint256 canceledItemsCount = _tokensCanceled.current();
        uint256 availableItemsCount = itemsCount - soldItemsCount - canceledItemsCount;
        MarketItem[] memory marketItems = new MarketItem[](availableItemsCount);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
           
            MarketItem memory item = marketItemIdToMarketItem[i + 1];
            if (item.owner != address(0)) continue;
            marketItems[currentIndex] = item;
            currentIndex += 1;
        }

        return marketItems;
    }

  
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

   
    function getMarketItemAddressByProperty(MarketItem memory item, string memory property)
        private
        pure
        returns (address)
    {
        require(
            compareStrings(property, "seller") || compareStrings(property, "owner"),
            "Parameter must be 'seller' or 'owner'"
        );

        return compareStrings(property, "seller") ? item.seller : item.owner;
    }

    
    function fetchSellingMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("seller");
    }

  
    function fetchOwnedMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("owner");
    }

 
    function fetchMarketItemsByAddressProperty(string memory _addressProperty)
        public
        view
        returns (MarketItem[] memory)
    {
        require(
            compareStrings(_addressProperty, "seller") || compareStrings(_addressProperty, "owner"),
            "Parameter must be 'seller' or 'owner'"
        );
        uint256 totalItemsCount = _marketItemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemsCount; i++) {
     
            MarketItem storage item = marketItemIdToMarketItem[i + 1];
            address addressPropertyValue = getMarketItemAddressByProperty(item, _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            itemCount += 1;
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemsCount; i++) {
          
            MarketItem storage item = marketItemIdToMarketItem[i + 1];
            address addressPropertyValue = getMarketItemAddressByProperty(item, _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            items[currentIndex] = item;
            currentIndex += 1;
        }

        return items;
    }
}