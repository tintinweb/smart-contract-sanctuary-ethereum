// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Logistics {
    struct Location {
        string name;
        uint timestamp;
    }
    
    struct Item {
        string name;
        string description;
        Location[] locations;
    }
    
    mapping(uint => Item) private items;
    mapping(address => uint[]) private ownerItems;
    uint private nextItemId = 1;
    
    event ItemCreated(uint itemId, string name, string description);
    event ItemMoved(uint itemId, string location);
    event ItemOwnershipTransferred(uint itemId, address from, address to);
    
    function createItem(string calldata name, string calldata description) external {
        Item storage newItem = items[nextItemId];
        newItem.name = name;
        newItem.description = description;
        ownerItems[msg.sender].push(nextItemId);
        emit ItemCreated(nextItemId, name, description);
        nextItemId++;
    }
    
    function moveItem(uint itemId, string calldata location) external {
        Item storage item = items[itemId];
        item.locations.push(Location(location, block.timestamp));
        emit ItemMoved(itemId, location);
    }
    
    function getItemLocations(uint itemId) external view returns(Location[] memory) {
        return items[itemId].locations;
    }

    function transferItem(uint itemId, address to) external {
    require(ownerOf(itemId) == msg.sender, "You must own this item to transfer it.");
        for(uint i = 0; i < ownerItems[msg.sender].length; i++) {
            if (ownerItems[msg.sender][i] == itemId) {
                ownerItems[msg.sender][i] = ownerItems[msg.sender][ownerItems[msg.sender].length - 1];
                ownerItems[msg.sender].pop();
                ownerItems[to].push(itemId);
                break;
            }
        }
        emit ItemOwnershipTransferred(itemId, msg.sender, to);
    }
    
    function ownerOf(uint itemId) public view returns (address) {
        for(uint i = 0; i < ownerItems[msg.sender].length; i++) {
            if (ownerItems[msg.sender][i] == itemId) {
                return msg.sender;
            }
        }
        return address(0);
    }
}