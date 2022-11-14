/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ItemStorage {

    struct Item {
        uint id;
        string nameOfItem;
        string value;
        uint lastUpdated;
    }
    Item[] itemsList;
    address owner = 0xD31B40ED3989DCC8145336249cE70Fdc73A3fE5c;

    function getItems(uint _startDate, uint _endDate) public view returns (Item[] memory) {

        uint length = 0;
        for(uint i = 0; i < itemsList.length; i++){
            if(itemsList[i].lastUpdated >= _startDate && itemsList[i].lastUpdated <= _endDate){
                length++;
            }
        }

        Item[] memory returnedItems = new Item[](length);

        for(uint i = 0; i < itemsList.length; i++){
            if(itemsList[i].lastUpdated >= _startDate && itemsList[i].lastUpdated <= _endDate){
                returnedItems[i]=itemsList[i];
            }
        }
        return returnedItems;
    }

    function createItem(string memory _nameOfItem, string memory _value) public returns (string memory) {
        // Get the address of the owner of the contract
        if (owner == msg.sender) {
            Item memory item = Item({id: itemsList.length, nameOfItem: _nameOfItem, value: _value, lastUpdated: block.timestamp });
            itemsList.push(item);
            return "Item added";
        }
        else {
            revert("You are not the owner of the contract");
        }
    }
}