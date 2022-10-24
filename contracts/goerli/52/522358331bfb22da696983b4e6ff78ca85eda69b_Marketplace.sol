// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Counters {
    struct Counter {
        uint _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint value = counter._value;
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

    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

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

    Counters.Counter private _itemIds;
    Counters.Counter private _soldItems;
    Counters.Counter private _canceledItems;

    address public base;
    address public _ve;
    address public minter;

    uint private listingFee = 40; // 2.5%

    mapping(uint => uint) public listed; // tokenId to MarketItemId

    mapping(uint => Item) private items;

    struct Item {
        uint itemId;
        uint tokenId;
        address seller;
        address buyer;
        uint startPrice;
        uint startDate;
        bool canceled;
    }

    event ItemCreated(
        uint indexed itemId,
        uint indexed tokenId,
        address seller,
        address buyer,
        uint startPrice,
        uint startDate,
        bool canceled
    );
    event ItemCanceled(
        uint indexed itemId,
        address seller
    );
    event ItemSold(
        uint indexed itemId,
        uint indexed tokenId,
        address seller,
        address buyer,
        uint netPrice,
        uint fee
    );
    event MarketplaceFeeSet(address indexed emergencyDAO, uint listingFee);

    constructor(address _minter, address _base, address ve_) {
        minter = _minter;
        base = _base;
        _ve = ve_;
    }

    function getListingFee() public view returns (uint) {
        return listingFee;
    }

    function setListingFee(uint _listingFee) public {
        require(msg.sender == ve(_ve).ownerOf(1), "Emergency DAO privilege: setListingFee");
        require(_listingFee >= 2 && _listingFee <= 1000);
        listingFee = _listingFee;
        emit MarketplaceFeeSet(msg.sender, _listingFee);
    }

    function calculateFee(uint price) public view returns (uint) {
        return price / listingFee;
    }

    function _calculatePrice(uint itemId) internal view returns (uint) {
        uint tokenId = items[itemId].tokenId;
        uint duration = ve(_ve).locked__end(tokenId) - items[itemId].startDate;
        uint past = (block.timestamp - 86400) / 86400 * 86400 - items[itemId].startDate;
        return past < duration? 
        items[itemId].startPrice + past * (uint(int256(ve(_ve).locked__amount(tokenId))) - items[itemId].startPrice) / duration
        : uint(int256(ve(_ve).locked__amount(tokenId)));
    }

    function calculatePrice(uint itemId) public view returns (uint) {
        return _calculatePrice(itemId);
    }

    /**
     * @dev Creates a market item listing
     */
    function createListing(
        uint tokenId,
        uint startPrice
    ) public nonReentrant returns (uint) {
        require(msg.sender == ve(_ve).ownerOf(tokenId), "Not NFT owner");
        require(listed[tokenId] == 0, "Listed");
        require(startPrice > 0, "No price");
        require(ve(_ve).isApprovedForAll(msg.sender, address(this)), "Marketplace not approved");
        _itemIds.increment();
        uint itemId = _itemIds.current();
        uint today = (block.timestamp - 86400) / 86400 * 86400;

        listed[tokenId] = itemId;

        items[itemId] = Item(
            itemId,
            tokenId,
            msg.sender,
            address(0),
            startPrice,
            today,
            false
        );

        emit ItemCreated(itemId, tokenId, msg.sender, address(0), startPrice, today, false);

        return itemId;
    }

    /**
     * @dev Cancel a market item
     */
    function cancelListing(uint itemId) external nonReentrant {
        require(msg.sender == items[itemId].seller || msg.sender == _ve, "Not approved");
        require(items[itemId].canceled == false, "Listing canceled");
        require(listed[items[itemId].tokenId] != 0, "Not listed");

        items[itemId].canceled = true;
        listed[items[itemId].tokenId] = 0;

        _canceledItems.increment();

        emit ItemCanceled(itemId, msg.sender);
    }

    /**
     * @dev Getter for listed
     */
    function getListed(uint tokenId) external view returns (uint) {
        return listed[tokenId];
    }

    /**
     * @dev Get Latest Market Item by the token id
     */
    function getLatestMarketItemByTokenId(uint tokenId) public view returns (Item memory, bool) {
        uint itemsCount = _itemIds.current();

        for (uint i = itemsCount; i > 0; i--) {
            Item memory item = items[i];
            if (item.tokenId != tokenId) continue;
            return (item, true);
        }

        // What is the best practice for returning a "null" value in solidity?
        // Reverting does't seem to be the best approach as it would throw an error on frontend
        Item memory emptyMarketItem;
        return (emptyMarketItem, false);
    }

    /**
     * @dev Creates a market sale by transfering msg.sender money to the seller and NFT token from the
     * seller to the msg.sender. It also sends the listingFee to the Minter.
     */
    function createSale(uint itemId, uint price) public nonReentrant {
        uint tokenId = items[itemId].tokenId;
        address seller = items[itemId].seller;
        require(listed[tokenId] != 0, "Not listed");
        require(seller == ve(_ve).ownerOf(tokenId), "Seller is not owner");
        require(ve(_ve).isApprovedForAll(seller, address(this)), "Marketplace not approved");
        require(price >= _calculatePrice(itemId), "Price too low");

        uint fee = calculateFee(price);
        price -= fee;

        // Must be before NFT transfer or Ve contract will cancel listing on transfer 
        listed[tokenId] = 0;

        _safeTransferFrom(base, msg.sender, minter, fee);
        _safeTransferFrom(base, msg.sender, seller, price);
        ve(_ve).transferFrom(seller, msg.sender, tokenId);

        items[itemId].buyer = msg.sender;

        _soldItems.increment();

        emit ItemSold(itemId, tokenId, seller, msg.sender, price, fee);
    }

    /**
     * @dev Fetch non sold and non canceled market items
     */
    function getListings() public view returns (Item[] memory) {
        uint itemsCount = _itemIds.current();
        uint soldItemsCount = _soldItems.current();
        uint canceledItemsCount = _canceledItems.current();
        uint availableItemsCount = itemsCount - soldItemsCount - canceledItemsCount;
        Item[] memory marketItems = new Item[](availableItemsCount);

        uint currentIndex = 0;
        for (uint i = 0; i < itemsCount; i++) {
            // Is this refactor better than the original implementation?
            // https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/Market.sol#L111
            // If so, is it better to use memory or storage here?
            Item storage item = items[i + 1];
            if (item.canceled == true || item.buyer != address(0)) continue;
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
     * we're looking for between "buyer" and "seller"
     */
    function getMarketItemAddressByProperty(Item memory item, string memory property)
        private
        pure
        returns (address)
    {
        require(
            compareStrings(property, "seller") || compareStrings(property, "buyer"),
            "Parameter must be 'seller' or 'buyer'"
        );

        return compareStrings(property, "seller") ? item.seller : item.buyer;
    }

    /**
     * @dev Fetch market items that are being listed by the msg.sender
     */
    function fetchSellingMarketItems() public view returns (Item[] memory) {
        return fetchMarketItemsByAddressProperty("seller");
    }

    /**
     * @dev Fetch market items that are owned by the msg.sender
     */
    function fetchOwnedMarketItems() public view returns (Item[] memory) {
        return fetchMarketItemsByAddressProperty("buyer");
    }

    /**
     * @dev Fetches market items according to the its requested address property that
     * can be "buyer" or "seller". The original implementations were two functions that were
     * almost the same, changing only a property access. This refactored version requires an
     * addional auxiliary function, but avoids repeating code.
     * See original: https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/blob/main/contracts/Market.sol#L121
     */
    function fetchMarketItemsByAddressProperty(string memory _addressProperty)
        public
        view
        returns (Item[] memory)
    {
        require(
            compareStrings(_addressProperty, "seller") || compareStrings(_addressProperty, "buyer"),
            "Parameter must be 'seller' or 'buyer'"
        );
        uint totalItemsCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemsCount; i++) {
            address addressPropertyValue = getMarketItemAddressByProperty(items[i + 1], _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            itemCount += 1;
        }

        Item[] memory currentItems = new Item[](itemCount);

        for (uint i = 0; i < totalItemsCount; i++) {
            address addressPropertyValue = getMarketItemAddressByProperty(items[i + 1], _addressProperty);
            if (addressPropertyValue != msg.sender) continue;
            currentItems[currentIndex] = items[i + 1];
            currentIndex += 1;
        }

        return currentItems;
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}