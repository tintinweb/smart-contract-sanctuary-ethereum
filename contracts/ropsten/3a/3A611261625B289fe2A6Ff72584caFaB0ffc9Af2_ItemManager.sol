// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Item.sol";
import "./Order.sol";
import "./Counters.sol";

contract ItemManager is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private itemIndex;
    enum ItemState {
        Created,
        Sold,
        Delivered,
        Cancelled
    }
    struct S_Item {
        Item _item;
        Order _order;
        ItemManager.ItemState _state;
    }
    mapping(uint256 => S_Item) public items;

    event ItemStateChanged(uint256 indexed itemIndex, uint8 state);

    modifier itemFound(uint256 _itemIndex) {
        require(
            _itemIndex < itemIndex.current(),
            "ItemManager: item not found!"
        );
        _;
    }

    modifier onlyItemOwner(uint256 _itemIndex) {
        require(
            items[_itemIndex]._item.owner() == _msgSender(),
            "ItemManager: caller is not the Item owner"
        );
        _;
    }

    // 0x3031303230333034000000000000000000000000000000000000000000000000
    // 0x4d741b6f1eb29cb2a9b9911c82f56fa8d73b04959d3d9d222895df6c0b28aa15
    
    function createItem(
        string memory _name,
        string memory _specifications,
        bytes32 _rawDataHash,
        uint256 _price
    ) public {
        uint256 curentItemIndex = itemIndex.current();
        Item item = new Item(
            this,
            _msgSender(),
            _name,
            _specifications,
            _rawDataHash,
            _price,
            curentItemIndex
        );
        S_Item storage s_item = items[curentItemIndex];
        s_item._item = item;
        s_item._state = ItemState.Created;
        emit ItemStateChanged(curentItemIndex, uint8(s_item._state));
        itemIndex.increment();
    }

    function triggerDelivered(uint256 _itemIndex) public itemFound(_itemIndex) {
        require(
            items[_itemIndex]._state == ItemState.Sold,
            "ItemManager: this item has not been purchased"
        );
        require(
            address(items[_itemIndex]._order) == _msgSender(),
            "ItemManager: this function must be call from Order contract"
        );
        items[_itemIndex]._item.transferOwnership(items[_itemIndex]._order.purchaser(), address(items[_itemIndex]._order));
        items[_itemIndex]._state = ItemState.Delivered;
        emit ItemStateChanged(_itemIndex, uint8(items[_itemIndex]._state));
    }

    function triggerPayment(
        uint256 _itemIndex,
        address _purchaser,
        address _owner
    ) public payable itemFound(_itemIndex) {
        S_Item storage s_item = items[_itemIndex];
        require(
            _msgSender() == address(s_item._item),
            "ItemManager: this function must be call from Item contract"
        );
        require(
            s_item._state == ItemState.Created,
            "ItemManager: this item is further on chain"
        );
        Order order = new Order{value: msg.value}(
            _purchaser,
            _owner,
            s_item._item
        );
        s_item._order = order;
        s_item._state = ItemState.Sold;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function triggerResale(uint256 _itemIndex, uint256 _price)
        public
        itemFound(_itemIndex)
        onlyItemOwner(_itemIndex)
    {
        S_Item storage s_item = items[_itemIndex];
        require(
            s_item._state == ItemState.Delivered || s_item._state == ItemState.Cancelled,
            'ItemManager: This item state must be "Delivered" or "Cancelled" to make for resale!'
        );
        s_item._item.changePrice(_price);
        s_item._state = ItemState.Created;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function triggerCancel(uint256 _itemIndex)
        public
        itemFound(_itemIndex)
    {
        S_Item storage s_item = items[_itemIndex];
        require(
            address(items[_itemIndex]._order) == _msgSender(),
            "ItemManager: this function must be call from Order contract"
        );
        require(
            s_item._state == ItemState.Sold,
            "ItemManager: this item is further on chain"
        );
        s_item._item.changePrice(0);
        s_item._state = ItemState.Cancelled;
        emit ItemStateChanged(_itemIndex, uint8(s_item._state));
    }

    function currentItemIndex() public view returns (uint256) {
        return itemIndex.current();
    }

    receive() external payable {}

    fallback() external payable {}
}