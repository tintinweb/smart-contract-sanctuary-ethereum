/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract LitRoad {
    // Item to sell
    struct Item {
        address seller; // Address of content creator. Gets 98% of sale
        address investor; // Address of user paying for tx fees. Gets 2% of sale
        string uri; // Metadata uri: https://ipfs.infura.io/ipfs/QmNTysYtyArCAYrh9WDzyzLZP9qimwd2aYgnAnvUrRFAMD
        uint256 price; // Price of item in smallest unit (wei)
    }

    // Stores all items: itemId => Item
    mapping(uint256 => Item) public items;

    // Check if itemId has been purchaed by buyer: itemId => buyer address => true
    mapping(uint256 => mapping(address => bool)) public purchase;

    // Balance of sellers: 0xAlice => 99 wei
    mapping(address => uint256) public balances;

    // Events
    event Sell(
        uint256 indexed _itemId,
        address indexed _seller,
        address indexed _investor,
        string _uri,
        uint256 _price
    );
    event Buy(uint256 indexed _itemId, address indexed _buyer, uint256 _amount);
    event Withdraw(address indexed _to, uint256 _amount);

    // Method to list and sell item
    function sell(
        uint256 _itemId,
        address _seller,
        address _investor,
        string memory _uri,
        uint256 _price
    ) public {
        require(items[_itemId].seller == address(0), "Item Already Listed");
        require(items[_itemId].investor == address(0), "Item Already Listed");
        // create item to sell
        items[_itemId] = Item({
            seller: _seller,
            investor: _investor,
            uri: _uri,
            price: _price
        });
        // emit Sell event
        emit Sell(_itemId, _seller, _investor, _uri, _price);
    }

    // Method to buy item
    function buy(uint256 _itemId) public payable {
        require(msg.value >= items[_itemId].price, "Insufficient Funds");
        require(purchase[_itemId][msg.sender] == false, "Already Purchased");
        // Set purchase to true
        purchase[_itemId][msg.sender] = true;
        // Seller gets 98% of sale
        uint256 sellerValue = (msg.value * 98) / 100;
        // Investory gets 2% of sale
        uint256 investorValue = (msg.value * 2) / 100;
        // Deposit into seller's account
        balances[items[_itemId].seller] += sellerValue;
        // Depost into investor's account
        balances[items[_itemId].investor] += investorValue;
        // emit Buy event
        emit Buy(_itemId, msg.sender, msg.value);
    }

    // Method to withdraw funds
    function withdraw(address _to) public payable {
        require(balances[_to] > 0, "Insufficient Funds");
        // get amount to withdraw
        uint256 amount = balances[_to];
        // set balance to 0
        balances[_to] = 0;
        // withdraw amount
        payable(_to).transfer(amount);
        // emit Withdraw event
        emit Withdraw(_to, amount);
    }
}