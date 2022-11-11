/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Helloworld {

    struct Item {
        uint id;
        string nameOfItem;
        string value;
    }
    Item[] public itemsList;
    address owner = 0x3F1d308983c2dD2A0f51875eab4A827ce22588cF;

    function getItems() public view returns (Item[] memory) {
        return itemsList;
    }

    function createItem(string memory _nameOfItem, string memory _value) public returns (string memory) {
        // Get the address of the owner of the contract
        if (owner == msg.sender) {
            Item memory item = Item({id: itemsList.length, nameOfItem: _nameOfItem, value: _value });
            itemsList.push(item);
            return "Item added";
        }
        else {
            revert("You are not the owner of the contract");
        }
    }

}