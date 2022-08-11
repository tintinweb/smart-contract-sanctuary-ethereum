/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.0;

contract CorruptionsInventory {
    address public owner;

    struct Item {
        string name;
        string description;
        uint256 quantity;
    }
    
    mapping(address => bool) public allowList;
    mapping(uint256 => Item) public items;

    uint256 public itemCount;
    
    constructor() {
        owner = msg.sender;
        allowList[msg.sender] = true;
    }

    function modifyAllowList(address allowedAddress, bool allowed) public {
        require(msg.sender == owner, "CorruptionsInventory: not owner");
        allowList[allowedAddress] = allowed;
    }

    function addItem(string memory name, string memory description, uint256 quantity) public {
        require(allowList[msg.sender] == true, "CorruptionsInventory: not allowed");
        items[itemCount].name = name;
        items[itemCount].description = description;
        items[itemCount].quantity = quantity;
        itemCount++;
    }

    function addQuantity(uint256 itemID, uint256 amount) public {
        require(allowList[msg.sender] == true, "CorruptionsInventory: not allowed");
        items[itemID].quantity += amount;
    }

    function subtractQuantity(uint256 itemID, uint256 amount) public {
        require(allowList[msg.sender] == true, "CorruptionsInventory: not allowed");
        require(items[itemID].quantity >= amount, "CorruptionsInventory: not enough quantity");
        items[itemID].quantity -= amount;
    }
}