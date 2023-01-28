/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Dappazon {
  event Add(string name, uint256 cost, uint256 quantity);
  event Buy(address buyer, uint256 orderID, uint256 itemID);
  struct Item {
    uint256 id;
    string name;
    string category;
    string image;
    uint256 cost;
    uint256 rating;
    uint256 stock;
  }

  struct Order {
    uint256 time;
    Item item;
  }

  address public owner;
  mapping(uint256 => Item) public items;
  mapping(address => uint256) public orderCount;
  mapping(address => mapping(uint256 => Order)) public orders;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  // Add Products
  function add(
    uint256 _id,
    string memory _name,
    string memory _category,
    string memory _image,
    uint256 _cost,
    uint256 _rating,
    uint256 _stock
  ) external onlyOwner {
    // Create an item
    Item memory item = Item(
      _id,
      _name,
      _category,
      _image,
      _cost,
      _rating,
      _stock
    );

    // Add item to array
    items[_id] = item;

    // Emit Add event
    emit Add(_name, _cost, _stock);
  }

  // Buy Products
  function buy(uint256 _id) external payable {
    // Fetch item
    Item storage item = items[_id];

    // Require a certain amount of eth to be sent and item is in stock
    require(item.stock > 0);
    require(msg.value >= item.cost, "Transfer the correct amount of ETH");

    // Create order
    Order memory order = Order(block.timestamp, item);

    // Save order to chain
    orderCount[msg.sender]++;
    orders[msg.sender][orderCount[msg.sender]] = order;

    // Subtract stock
    items[_id].stock--;

    // Emit buy event
    emit Buy(msg.sender, orderCount[msg.sender], item.id);
  }

  // Withdraw funds
  function withdraw() external onlyOwner {
    (bool success, ) = owner.call{value: address(this).balance}("");
    require(success, "Transaction unsuccessful");
  }
}