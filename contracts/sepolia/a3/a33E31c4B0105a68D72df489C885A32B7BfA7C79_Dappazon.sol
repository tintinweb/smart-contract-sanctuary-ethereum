// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Dappazon {
    /**EVENTS */
    event List(string indexed name, uint256 cost, uint256 quantity);
    event Buy(address indexed buyer, uint256 indexed orderId, uint256 itemId);
    string public name;
    address private immutable owner;
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
    mapping(uint256 => Item) public items;
    mapping(address => uint256) public orderCount;
    mapping(address => mapping(uint256 => Order)) public orders;

    constructor() {
        name = "Dappazon";
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    // List products
    function list(
        uint256 _id,
        string memory _name,
        string memory _category,
        string memory _image,
        uint256 _cost,
        uint256 _rating,
        uint256 _stock
    ) public isOwner {
        Item memory item = Item(
            _id,
            _name,
            _category,
            _image,
            _cost,
            _rating,
            _stock
        );
        items[_id] = item;
        emit List(_name, _cost, _stock);
    }

    //buy products
    function buy(uint256 _id) public payable {
        //receive crypto
        require(
            msg.value >= items[_id].cost,
            "You need to spend more ETH to buy"
        );
        require(items[_id].stock > 0, "Item out of stock");
        //create an order
        Order memory order = Order(block.timestamp, items[_id]);
        // Save order to chain
        orderCount[msg.sender]++;
        orders[msg.sender][orderCount[msg.sender]] = order;
        //substract stock
        items[_id].stock = items[_id].stock - 1;
        // Emit event
        emit Buy(msg.sender, orderCount[msg.sender], _id);
    }

    // withdraw funds
    function withdraw() public payable isOwner() {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success);
    }
}