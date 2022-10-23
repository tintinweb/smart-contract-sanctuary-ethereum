/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

interface ve {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function locked__amount(uint tokenId) external view returns (int128);
    function locked__end(uint _tokenId) external view returns (uint);
}


interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}


abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}


contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _marketItemIds;
    Counters.Counter private _tokensSold;
    Counters.Counter private _tokensCanceled;

    address public base;
    address public minter;
    address public _ve;

    uint256 private listingFee = 40; // 2.5%

    mapping(uint256 => uint256) public listed; // tokenId to MarketItemId

    mapping(uint256 => MarketItem) private marketItemIdToMarketItem;

    struct MarketItem {
        uint256 marketItemId;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 startingprice;
        uint256 createdAtBlock;
        bool sold;
        bool canceled;
    }

    event MarketItemCreated(
        uint256 indexed marketItemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 startingprice,
        uint256 createdAtBlock,
        bool sold,
        bool canceled
    );
    event MarketplaceFeeSet(address indexed emergencyDAO, uint256 listingFee);

    constructor(address _minter, address _base, address ve_) {
        minter = _minter;
        base = _base;
        _ve = ve_;
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function setListingFee(uint256 _listingFee) public {
        require(msg.sender == ve(_ve).ownerOf(1), "Emergency DAO privilege: setListingFee");
        require(_listingFee >= 2 && _listingFee <= 1000);
        listingFee = _listingFee;
        emit MarketplaceFeeSet(msg.sender, _listingFee);
    }

    function calculateFee(uint256 price) public view returns (uint256) {
        return price / listingFee;
    }

    function calculatePrice(uint256 marketItemId) public view returns (uint256) {
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        uint256 duration = ve(_ve).locked__end(tokenId) - marketItemIdToMarketItem[marketItemId].createdAtBlock;
        uint256 past = block.number - marketItemIdToMarketItem[marketItemId].createdAtBlock;
        uint256 discount = uint(int256(ve(_ve).locked__amount(tokenId))) - marketItemIdToMarketItem[marketItemId].startingprice;
        return marketItemIdToMarketItem[marketItemId].startingprice + past * discount / duration;
    }

    /**
     * @dev Creates a market item listing
     */
    function createMarketItem(
        uint256 tokenId,
        uint256 startingprice
    ) public nonReentrant returns (uint256) {
        require(msg.sender == ve(_ve).ownerOf(tokenId), "Not NFT owner");
        require(listed[tokenId] == 0, "Listed");
        require(startingprice > 0, "No price");
        require(ve(_ve).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        _marketItemIds.increment();
        uint256 marketItemId = _marketItemIds.current();

        listed[tokenId] = marketItemId;

        marketItemIdToMarketItem[marketItemId] = MarketItem(
            marketItemId,
            tokenId,
            msg.sender,
            msg.sender,
            startingprice,
            block.number,
            false,
            false
        );

        emit MarketItemCreated(
            marketItemId,
            tokenId,
            msg.sender,
            msg.sender,
            startingprice,
            block.number,
            false,
            false
        );

        return marketItemId;
    }

    /**
     * @dev Cancel a market item
     */
    function cancelMarketItem(uint256 marketItemId) external nonReentrant {
        require(msg.sender == marketItemIdToMarketItem[marketItemId].seller || msg.sender == _ve, "Not approved");
        require(marketItemIdToMarketItem[marketItemId].canceled == false, "Listing canceled");
        require(listed[marketItemIdToMarketItem[marketItemId].tokenId] != 0, "Not listed");

        marketItemIdToMarketItem[marketItemId].canceled = true;
        listed[marketItemIdToMarketItem[marketItemId].tokenId] = 0;

        _tokensCanceled.increment();
    }

    /**
     * @dev Getter for listed
     */
    function getListed(uint256 tokenId) external view returns (uint256) {
        return listed[tokenId];
    }

    /**
     * @dev Get Latest Market Item by the token id
     */
    function getLatestMarketItemByTokenId(uint256 tokenId) public view returns (MarketItem memory, bool) {
        uint256 itemsCount = _marketItemIds.current();

        for (uint256 i = itemsCount; i > 0; i--) {
            MarketItem memory item = marketItemIdToMarketItem[i];
            if (item.tokenId != tokenId) continue;
            return (item, true);
        }

        // What is the best practice for returning a "null" value in solidity?
        // Reverting does't seem to be the best approach as it would throw an error on frontend
        MarketItem memory emptyMarketItem;
        return (emptyMarketItem, false);
    }

    /**
     * @dev Creates a market sale by transfering msg.sender money to the seller and NFT token from the
     * seller to the msg.sender. It also sends the listingFee to the Minter.
     */
    function createMarketSale(uint256 marketItemId) public nonReentrant {
        require(ve(_ve).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        uint256 tokenId = marketItemIdToMarketItem[marketItemId].tokenId;
        require(listed[tokenId] != 0, "Not listed");
        address seller = marketItemIdToMarketItem[marketItemId].seller;
        require(seller == ve(_ve).ownerOf(tokenId), "Seller is not owner");

        uint256 price = calculatePrice(marketItemId);
        uint256 fee = calculateFee(price);
        price -= fee;

        // Must be before NFT transfer or Ve contract will cancel listing on transfer 
        listed[tokenId] = 0;

        _safeTransferFrom(base, msg.sender, minter, fee);
        _safeTransferFrom(base, msg.sender, seller, price);
        ve(_ve).transferFrom(seller, msg.sender, tokenId);

        marketItemIdToMarketItem[marketItemId].owner = msg.sender;
        marketItemIdToMarketItem[marketItemId].sold = true;

        _tokensSold.increment();
    }

    /**
     * @dev Fetch non sold and non canceled market items
     */
    function fetchAvailableMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemsCount = _marketItemIds.current();
        uint256 soldItemsCount = _tokensSold.current();
        uint256 canceledItemsCount = _tokensCanceled.current();
        uint256 availableItemsCount = itemsCount - soldItemsCount - canceledItemsCount;
        MarketItem[] memory marketItems = new MarketItem[](availableItemsCount);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < itemsCount; i++) {
            // Is this refactor better than the original implementation?
            // https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/Market.sol#L111
            // If so, is it better to use memory or storage here?
            MarketItem storage item = marketItemIdToMarketItem[i + 1];
            if (item.canceled == false && item.sold == false) continue;
            marketItems[currentIndex] = item;
            currentIndex += 1;
        }

        return marketItems;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev Since we can't access structs properties dinamically, this function selects the address
     * we're looking for between "owner" and "seller"
     */
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

    /**
     * @dev Fetch market items that are being listed by the msg.sender
     */
    function fetchSellingMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("seller");
    }

    /**
     * @dev Fetch market items that are owned by the msg.sender
     */
    function fetchOwnedMarketItems() public view returns (MarketItem[] memory) {
        return fetchMarketItemsByAddressProperty("owner");
    }

    /**
     * @dev Fetches market items according to the its requested address property that
     * can be "owner" or "seller". The original implementations were two functions that were
     * almost the same, changing only a property access. This refactored version requires an
     * addional auxiliary function, but avoids repeating code.
     * See original: https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/Market.sol#L121
     */
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
            address addressPropertyValue = getMarketItemAddressByProperty(marketItemIdToMarketItem[i + 1], _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            itemCount += 1;
        }

        MarketItem[] memory items = new MarketItem[](itemCount);

        for (uint256 i = 0; i < totalItemsCount; i++) {
            address addressPropertyValue = getMarketItemAddressByProperty(marketItemIdToMarketItem[i + 1], _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            items[currentIndex] = marketItemIdToMarketItem[i + 1];
            currentIndex += 1;
        }

        return items;
    }

        function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}