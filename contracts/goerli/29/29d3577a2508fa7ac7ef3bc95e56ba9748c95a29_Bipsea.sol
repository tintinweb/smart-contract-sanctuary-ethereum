/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Bipsea {
    // Owner address can delist inappropriate items. Will delegate to DAO
    address public owner;

    // Item to sell
    struct Item {
        address seller;     // Address of content creator. Gets 99% of sale
        address investor;   // Address of user paying for tx fees. Gets 1% of sale
        string  uri;        // Metadata uri: https://ipfs.io/ipfs/bafkreigjdoplg6qattgtkx7zrfreky3xjk52dpxeqxf7bqx7funa2z6vpu
        uint256 price;      // Price of item in smallest unit (wei)
        bool    canBuy;     // Boolean to enable buying
    }

    // Stores all items: itemId => Item
    mapping(uint256 => Item) public items;

    // Check if itemId has been purchaed by buyer: itemId => buyer address => true
    mapping(uint256 => mapping(address => bool)) public purchase;

    // Events
    event Sell(uint256 _itemId);
    event Buy(uint256 indexed _itemId, address indexed _buyer, uint256 _amount);
    event Delist(uint256 indexed _itemId, address indexed _seller);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Sell item
    function sell(
        uint256 _itemId,
        address _seller,
        address _investor,
        string memory _uri,
        uint256 _price
    ) public {
        require(items[_itemId].seller == address(0), "Item Already Listed");
        require(items[_itemId].investor == address(0), "Item Already Listed");
        // Create item to sell
        items[_itemId] = Item({
            seller: _seller,
            investor: _investor,
            uri: _uri,
            price: _price,
            canBuy: true
        });
        // Emit Sell event
        emit Sell(_itemId);
    }

    // Buy item
    function buy(uint64 _itemId) public payable {
        require(msg.value >= items[_itemId].price, "Insufficient Funds");
        require(purchase[_itemId][msg.sender] == false, "Already Purchased");
        // Set purchase to true
        purchase[_itemId][msg.sender] = true;
        // Seller gets 99% of sale
        uint256 sellerValue = (msg.value * 99) / 100;
        // Investor gets 1% of sale
        uint256 investorValue = (msg.value * 1) / 100;
        // Send seller value to seller's account
        payable(items[_itemId].seller).transfer(sellerValue);
        // Send investor value to investor's account
        payable(items[_itemId].investor).transfer(investorValue);
        // Emit Buy
        emit Buy(_itemId, msg.sender, msg.value);
    }

    // Delist Item
    function delist(uint64 _itemId) public {
        require(msg.sender == items[_itemId].seller || msg.sender == owner, "Only seller || owner can delist");
        items[_itemId].canBuy = false;
        // Emit Delist
        emit Delist(_itemId, msg.sender);
    }

    // Set Owner
    function setOwner(address _newOwner) public {
        require(msg.sender == owner, "Only owner can set");
        owner = _newOwner;
    }

}