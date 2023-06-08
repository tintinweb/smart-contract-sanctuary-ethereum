// SPDX-License-Identifier: MIT

/// @title  Trust Marketplace
/// @author Harsh
/// @notice This contract is a marketplace contract, which will store the listed items
///         data,buyers data,sellers data and we can buy,sell, products here.
/// @dev  functions List,buy,withdraw(for the seller),add seller(to become a seller)
pragma solidity ^0.8.17;

contract TrustMart {
    //Events
    event List(string indexed name, uint256 cost, uint256 quantity);
    event Buy(address indexed buyer, uint256 indexed orderId, uint256 itemId);
    event SellerAdded(
        address indexed sellerAddress,
        string indexed name,
        uint256 Id
    );
    struct Seller {
        uint256 id;
        string name;
    }
    struct Item {
        uint256 id;
        string name;
        string category;
        string image;
        uint256 cost;
        uint256 rating;
        uint256 stock;
        address vendor;
    }
    struct Order {
        uint256 time;
        Item item;
    }
    mapping(uint256 => Item) public items;
    mapping(address => uint256) public orderCount;
    mapping(address => mapping(uint256 => Order)) public orders;
    mapping(address => Seller) public sellers;
    address private immutable owner;
    mapping(address => uint256) public addressToAmount;
    uint256 public numberOfItems;

    constructor() {
        owner = msg.sender;
        Seller memory seller = Seller(2000, "harsh");
        sellers[msg.sender] = seller;
        numberOfItems = 0;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    //modifier
    modifier isSeller() {
        require(
            msg.sender == owner || sellers[msg.sender].id > 0,
            "You are not the seller"
        );

        _;
    }

    //List
    function list(
        uint256 _id,
        string memory _name,
        string memory _category,
        string memory _image,
        uint256 _cost,
        uint256 _rating,
        uint256 _stock
    ) public isSeller {
        Item memory item = Item(
            _id,
            _name,
            _category,
            _image,
            _cost,
            _rating,
            _stock,
            msg.sender
        );
        items[_id] = item;
        emit List(_name, _cost, _stock);
        numberOfItems++;
    }

    function getItem(uint256 _id) public view returns (Item memory) {
        return items[_id];
    }

    // Add seller
    function becomeSeller(uint256 _id, string memory _name) public {
        Seller memory seller = Seller(_id, _name);
        sellers[msg.sender] = seller;
        emit SellerAdded(msg.sender, _name, _id);
    }

    function getSellerInfo(
        address _address
    ) public view returns (Seller memory) {
        return sellers[_address];
    }

    //buy
    function buy(uint256 _id) public payable {
        require(msg.value >= items[_id].cost, "You dont' have enough Crypto");
        require(items[_id].stock > 0, "Item out of stock");
        items[_id].stock = items[_id].stock - 1;
        orderCount[msg.sender]++;
        orders[msg.sender][orderCount[msg.sender]] = Order(
            block.timestamp,
            items[_id]
        );
        addressToAmount[items[_id].vendor] =
            addressToAmount[items[_id].vendor] +
            msg.value;
        emit Buy(msg.sender, orderCount[msg.sender], _id);
        numberOfItems--;
    }

    //withdraw
    function withdraw() public payable isSeller {
        uint256 amount = addressToAmount[msg.sender];
        addressToAmount[msg.sender] = 0;
        (bool success, ) = (msg.sender).call{value: amount}("");

        require(success);
    }
}