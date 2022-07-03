pragma solidity ^0.8.0;

contract SimpleStore {
    struct Item {
        uint256 units;
    }

    Item[] public items;

    //add new
    function newItem(uint256 _units) public {
        items.push(Item(_units));
    }

    //set - updates
    function setUsingMemory(uint256 _itemIdx, uint256 _val) public view {
        Item memory item = items[_itemIdx];
        item.units = _val;
    }

    function setUsingStorage(uint256 _itemIdx, uint256 _val) public {
        Item storage item = items[_itemIdx];
        item.units = _val;
    }

    function getItemAtIndex(uint256 _itemIdx) public view returns (uint256) {
        return items[_itemIdx].units;
    }
}